package testimpl

import (
	"context"
	"strconv"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/codebuild"
	codebuildtypes "github.com/aws/aws-sdk-go-v2/service/codebuild/types"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/launchbynttdata/lcaf-component-terratest/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestComposableComplete verifies the project, starts a build, and stops an
// unfinished build before the framework tears down the example infrastructure.
func TestComposableComplete(t *testing.T, ctx types.TestContext) {
	client, name := verifyProject(t, ctx)

	buildOutput, err := client.StartBuild(context.Background(), &codebuild.StartBuildInput{
		ProjectName: aws.String(name),
	})
	require.NoError(t, err)
	require.NotNil(t, buildOutput.Build)

	buildID := aws.ToString(buildOutput.Build.Id)
	require.NotEqual(t, "", buildID)
	defer stopBuildIfRunning(t, client, buildID)

	assert.Equal(t, codebuildtypes.StatusTypeSucceeded, waitForBuild(t, client, buildID))
}

// TestComposableCompleteReadOnly verifies the deployed project using only
// read-only CodeBuild API operations.
func TestComposableCompleteReadOnly(t *testing.T, ctx types.TestContext) {
	verifyProject(t, ctx)
}

func verifyProject(t *testing.T, ctx types.TestContext) (*codebuild.Client, string) {
	t.Helper()

	terraformOptions := ctx.TerratestTerraformOptions()
	terraformContext := context.Background()
	region := terraform.OutputContext(t, terraformContext, terraformOptions, "region")
	name := terraform.OutputContext(t, terraformContext, terraformOptions, "name")
	arn := terraform.OutputContext(t, terraformContext, terraformOptions, "arn")
	expectedArtifactBucket := terraform.OutputContext(t, terraformContext, terraformOptions, "expected_artifact_bucket")
	expectedBuildTimeout := terraform.OutputContext(t, terraformContext, terraformOptions, "expected_build_timeout")
	expectedEncryptionKeyARN := terraform.OutputContext(t, terraformContext, terraformOptions, "expected_encryption_key_arn")
	expectedDescription := terraform.OutputContext(t, terraformContext, terraformOptions, "expected_description")
	expectedTags := terraform.OutputMapContext(t, terraformContext, terraformOptions, "expected_tags")
	expectedBadgeEnabled := terraform.OutputContext(t, terraformContext, terraformOptions, "expected_badge_enabled")
	expectedCacheType := terraform.OutputContext(t, terraformContext, terraformOptions, "expected_cache_type")
	expectedEnvironmentVariables := terraform.OutputMapContext(t, terraformContext, terraformOptions, "expected_environment_variables")
	expectedEnvironmentComputeType := terraform.OutputContext(t, terraformContext, terraformOptions, "expected_environment_compute_type")
	expectedEnvironmentType := terraform.OutputContext(t, terraformContext, terraformOptions, "expected_environment_type")
	expectedSourceType := terraform.OutputContext(t, terraformContext, terraformOptions, "expected_source_type")

	client := codeBuildClient(t, region)
	projects, err := client.BatchGetProjects(context.Background(), &codebuild.BatchGetProjectsInput{
		Names: []string{name},
	})
	require.NoError(t, err)
	require.Emptyf(t, projects.ProjectsNotFound, "CodeBuild project %q was not found in region %q", name, region)
	require.Len(t, projects.Projects, 1)

	project := projects.Projects[0]
	require.NotNil(t, project.Artifacts)
	require.NotNil(t, project.EncryptionKey)
	require.NotNil(t, project.Environment)
	require.NotNil(t, project.Source)
	require.NotNil(t, project.TimeoutInMinutes)
	assert.Equal(t, name, aws.ToString(project.Name))
	assert.Equal(t, arn, aws.ToString(project.Arn))
	assert.Equal(t, expectedArtifactBucket, aws.ToString(project.Artifacts.Location))
	assert.Equal(t, expectedBuildTimeout, strconv.FormatInt(int64(aws.ToInt32(project.TimeoutInMinutes)), 10))
	assert.Equal(t, expectedEncryptionKeyARN, aws.ToString(project.EncryptionKey))
	assert.Equal(t, expectedDescription, aws.ToString(project.Description))
	assert.Equal(t, expectedTags, codeBuildTags(project.Tags))
	if expectedBadgeEnabled == "true" {
		require.NotNil(t, project.Badge)
		assert.True(t, project.Badge.BadgeEnabled)
	} else if project.Badge != nil {
		assert.False(t, project.Badge.BadgeEnabled)
	}
	if expectedCacheType != "" {
		require.NotNil(t, project.Cache)
		assert.Equal(t, expectedCacheType, string(project.Cache.Type))
	}
	assert.Equal(t, expectedEnvironmentVariables, codeBuildEnvironmentVariables(project.Environment.EnvironmentVariables))
	assert.Equal(t, expectedEnvironmentComputeType, string(project.Environment.ComputeType))
	assert.Equal(t, expectedEnvironmentType, string(project.Environment.Type))
	assert.Equal(t, expectedSourceType, string(project.Source.Type))

	return client, name
}

func codeBuildClient(t *testing.T, region string) *codebuild.Client {
	t.Helper()

	awsConfig, err := config.LoadDefaultConfig(context.Background(), config.WithRegion(region))
	require.NoError(t, err)

	return codebuild.NewFromConfig(awsConfig)
}

func waitForBuild(t *testing.T, client *codebuild.Client, buildID string) codebuildtypes.StatusType {
	t.Helper()

	const (
		maxAttempts          = 30
		maxConsecutiveErrors = 3
		pollInterval         = 10 * time.Second
	)

	consecutiveErrors := 0
	var latestBuild *codebuildtypes.Build
	for attempt := 0; attempt < maxAttempts; attempt++ {
		builds, err := client.BatchGetBuilds(context.Background(), &codebuild.BatchGetBuildsInput{
			Ids: []string{buildID},
		})
		if err != nil {
			consecutiveErrors++
			t.Logf("BatchGetBuilds attempt %d/%d failed for build %q: %v", attempt+1, maxAttempts, buildID, err)
			if consecutiveErrors >= maxConsecutiveErrors {
				t.Fatalf("BatchGetBuilds failed %d consecutive times while waiting for CodeBuild build %q", consecutiveErrors, buildID)
			}
			time.Sleep(pollInterval)
			continue
		}
		consecutiveErrors = 0
		if len(builds.Builds) == 0 && len(builds.BuildsNotFound) > 0 {
			t.Logf("BatchGetBuilds attempt %d/%d has not found build %q yet", attempt+1, maxAttempts, buildID)
			time.Sleep(pollInterval)
			continue
		}
		require.Emptyf(t, builds.BuildsNotFound, "CodeBuild build %q was not found", buildID)
		require.Len(t, builds.Builds, 1)

		build := builds.Builds[0]
		latestBuild = &build
		status := build.BuildStatus
		switch status {
		case codebuildtypes.StatusTypeSucceeded, codebuildtypes.StatusTypeFailed, codebuildtypes.StatusTypeFault,
			codebuildtypes.StatusTypeStopped, codebuildtypes.StatusTypeTimedOut:
			if status != codebuildtypes.StatusTypeSucceeded {
				logBuildDiagnostics(t, build)
			}
			return status
		default:
			time.Sleep(pollInterval)
		}
	}

	if latestBuild != nil {
		logBuildDiagnostics(t, *latestBuild)
	}
	t.Fatalf("CodeBuild build %q did not complete within %s", buildID, time.Duration(maxAttempts)*pollInterval)
	return ""
}

func stopBuildIfRunning(t *testing.T, client *codebuild.Client, buildID string) {
	t.Helper()

	builds, err := client.BatchGetBuilds(context.Background(), &codebuild.BatchGetBuildsInput{Ids: []string{buildID}})
	if err != nil {
		t.Logf("unable to determine whether CodeBuild build %q needs cleanup: %v", buildID, err)
		return
	}
	if len(builds.Builds) != 1 {
		t.Logf("unable to determine whether CodeBuild build %q needs cleanup: found %d build(s), not found: %v", buildID, len(builds.Builds), builds.BuildsNotFound)
		return
	}

	switch builds.Builds[0].BuildStatus {
	case codebuildtypes.StatusTypeSucceeded, codebuildtypes.StatusTypeFailed, codebuildtypes.StatusTypeFault,
		codebuildtypes.StatusTypeStopped, codebuildtypes.StatusTypeTimedOut:
		return
	}

	if _, err := client.StopBuild(context.Background(), &codebuild.StopBuildInput{Id: aws.String(buildID)}); err != nil {
		t.Logf("failed to stop CodeBuild build %q during cleanup: %v", buildID, err)
	}
}

func logBuildDiagnostics(t *testing.T, build codebuildtypes.Build) {
	t.Helper()

	for _, phase := range build.Phases {
		t.Logf("CodeBuild phase %s: %s", phase.PhaseType, phase.PhaseStatus)
		for _, phaseContext := range phase.Contexts {
			t.Logf("CodeBuild phase detail: status_code=%s message=%s", aws.ToString(phaseContext.StatusCode), aws.ToString(phaseContext.Message))
		}
	}
	if build.Logs != nil {
		t.Logf("CodeBuild logs: %s", aws.ToString(build.Logs.DeepLink))
	}
}

func codeBuildTags(tags []codebuildtypes.Tag) map[string]string {
	result := make(map[string]string, len(tags))
	for _, tag := range tags {
		result[aws.ToString(tag.Key)] = aws.ToString(tag.Value)
	}

	return result
}

func codeBuildEnvironmentVariables(environmentVariables []codebuildtypes.EnvironmentVariable) map[string]string {
	result := make(map[string]string, len(environmentVariables))
	for _, environmentVariable := range environmentVariables {
		result[aws.ToString(environmentVariable.Name)] = aws.ToString(environmentVariable.Value)
	}

	return result
}
