# Permissions required by Wiz to build its inventory of AWS resources.

resource "aws_iam_policy" "inventory" {
  name        = "WizInventoryPolicy"
  description = "Resource inventory permissions required by Wiz"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "InventoryReads"
        Action = [
          "aoss:ListAccessPolicies",
          "aoss:ListCollections",
          "aoss:ListSecurityPolicies",
          "appconfig:ListApplications",
          "appconfig:ListDeploymentStrategies",
          "appconfig:ListExtensionAssociations",
          "appconfig:ListExtensions",
          "appfabric:ListAppBundles",
          "applicationinsights:ListApplications",
          "appstream:DescribeAppBlockBuilders",
          "appstream:DescribeAppBlocks",
          "appstream:DescribeFleets",
          "appstream:DescribeImageBuilders",
          "appstream:DescribeImages",
          "appstream:DescribeStacks",
          "athena:GetDataCatalog",
          "b2bi:ListCapabilities",
          "b2bi:ListPartnerships",
          "b2bi:ListProfiles",
          "b2bi:ListTransformers",
          "backup-gateway:ListGateways",
          "backup:ListRestoreTestingPlans",
          "backup:ListTieringConfigurations",
          "bedrock:ListEnforcedGuardrailsConfiguration",
          "cloudhsm:DescribeClusters",
          "codeartifact:ListDomains",
          "codeconnections:ListHosts",
          "codepipeline:ListWebhooks",
          "ecr:DescribePullThroughCacheRules",
          "gamelift:DescribeFleetAttributes",
          "gamelift:DescribeGameSessionQueues",
          "gamelift:DescribeMatchmakingConfigurations",
          "gamelift:DescribeMatchmakingRuleSets",
          "glue:GetMLTransforms",
          "glue:ListWorkflows",
          "iotfleetwise:ListCampaigns",
          "lightsail:GetDomains",
          "lightsail:GetKeyPairs",
          "lightsail:GetRelationalDatabaseSnapshots",
          "lightsail:GetRelationalDatabases",
          "logs:ListLogAnomalyDetectors",
          "logs:ListScheduledQueries",
          "lookoutequipment:ListInferenceSchedulers",
          "lookoutequipment:ListModels",
          "memorydb:DescribeServiceUpdates",
          "memorydb:DescribeSnapshots",
          "network-firewall:ListTLSInspectionConfigurations",
          "network-firewall:ListVpcEndpointAssociations",
          "personalize:ListBatchInferenceJobs",
          "personalize:ListBatchSegmentJobs",
          "personalize:ListCampaigns",
          "personalize:ListDatasetExportJobs",
          "personalize:ListDatasetImportJobs",
          "personalize:ListDatasets",
          "personalize:ListEventTrackers",
          "personalize:ListFilters",
          "personalize:ListMetricAttributions",
          "personalize:ListRecommenders",
          "personalize:ListSchemas",
          "personalize:ListSolutions",
          "rbin:ListRules",
          "s3:GetIntelligentTieringConfiguration",
          "s3:GetStorageLensConfigurationTagging",
          "scheduler:ListSchedules",
          "servicediscovery:ListNamespaces",
          "sns:GetDataProtectionPolicy",
          "textract:ListAdapters",
          "timestream-influxdb:ListDbClusters",
          "timestream-influxdb:ListDbInstances",
          "transcribe:ListMedicalScribeJobs",
          "voiceid:ListDomains",
          "workmail:ListOrganizations",
          "workspaces-web:ListBrowserSettings",
          "workspaces-web:ListNetworkSettings",
          "workspaces-web:ListPortals",
          "workspaces-web:ListUserSettings",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Keep actions separate to stay below document size limit.
resource "aws_iam_policy" "inventory_additional" {
  name        = "WizInventoryAdditionalPolicy"
  description = "Additional resource inventory permissions required by Wiz"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "amplify:ListApps",
          "apigateway:ListPortalProducts",
          "apigateway:ListPortals",
          "app-integrations:ListApplications",
          "app-integrations:ListDataIntegrations",
          "app-integrations:ListEventIntegrations",
          "aps:ListWorkspaces",
          "batch:DescribeJobQueues",
          "batch:DescribeServiceEnvironments",
          "batch:ListConsumableResources",
          "cleanrooms-ml:ListAudienceGenerationJobs",
          "cleanrooms-ml:ListAudienceModels",
          "cleanrooms-ml:ListConfiguredAudienceModels",
          "cleanrooms-ml:ListConfiguredModelAlgorithms",
          "codeguru-profiler:ListProfilingGroups",
          "codestar-notifications:ListNotificationRules",
          "databrew:ListRecipes",
          "dataexchange:ListEventActions",
          "dataexchange:ListJobs",
          "datazone:ListDomains",
          "devops-guru:DescribeServiceIntegration",
          "dlm:GetLifecyclePolicies",
          "docdb-elastic:ListClusterSnapshots",
          "drs:DescribeLaunchConfigurationTemplates",
          "drs:DescribeRecoveryInstances",
          "drs:DescribeReplicationConfigurationTemplates",
          "drs:DescribeSourceNetworks",
          "drs:DescribeSourceServers",
          "dsql:ListClusters",
          "entityresolution:ListIdNamespaces",
          "entityresolution:ListMatchingWorkflows",
          "entityresolution:ListSchemaMappings",
          "fis:ListExperimentTemplates",
          "fis:ListExperiments",
          "imagebuilder:ListContainerRecipes",
          "imagebuilder:ListDistributionConfigurations",
          "imagebuilder:ListImagePipelines",
          "imagebuilder:ListImageRecipes",
          "imagebuilder:ListImages",
          "imagebuilder:ListInfrastructureConfigurations",
          "imagebuilder:ListLifecyclePolicies",
          "imagebuilder:ListWorkflows",
          "internetmonitor:ListMonitors",
          "iotsitewise:ListPortals",
          "lex:ListTestSets",
          "macie2:GetAutomatedDiscoveryConfiguration",
          "macie2:GetMacieSession",
          "managedblockchain:ListInvitations",
          "mediaconvert:ListJobTemplates",
          "mediaconvert:ListPresets",
          "mediaconvert:ListQueues",
          "mediatailor:ListChannels",
          "mediatailor:ListPlaybackConfigurations",
          "mediatailor:ListSourceLocations",
          "medical-imaging:ListDatastores",
          "neptune-graph:ListGraphSnapshots",
          "neptune-graph:ListGraphs",
          "networkmonitor:ListMonitors",
          "omics:ListReferenceStores",
          "omics:ListRunCaches",
          "omics:ListRunGroups",
          "omics:ListRuns",
          "omics:ListSequenceStores",
          "omics:ListWorkflows",
          "osis:ListPipelines",
          "pipes:ListPipes",
          "resiliencehub:ListApps",
          "resiliencehub:ListResiliencyPolicies",
          "resource-groups:GetAccountSettings",
          "resource-groups:ListGroups",
          "ssm-incidents:ListReplicationSets",
          "thinclient:ListEnvironments",
          "thinclient:ListSoftwareSets",
          "vpc-lattice:ListResourceConfigurations",
          "vpc-lattice:ListResourceGateways",
          "vpc-lattice:ListServiceNetworkResourceAssociations",
          "vpc-lattice:ListServiceNetworks",
          "vpc-lattice:ListServices",
          "vpc-lattice:ListTargetGroups",
          "wellarchitected:ListWorkloads",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "inventory" {
  role       = aws_iam_role.user-role-tf.name
  policy_arn = aws_iam_policy.inventory.arn
}

resource "aws_iam_role_policy_attachment" "inventory_additional" {
  role       = aws_iam_role.user-role-tf.name
  policy_arn = aws_iam_policy.inventory_additional.arn
}
