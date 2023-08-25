{
    "description" : "This document can be used to centralize your software package deployment solution across accounts and regions using AWS Systems Manager",
    "schemaVersion" : "0.3",
    "assumeRole" : "{{ AutomationAssumeRole }}",
    "parameters" : {
        "InstanceId" : {
        "type" : "String",
        "default" : "*"
        },
        "action" : {
        "description" : "(Required) Specify whether or not to install or uninstall the package.",
        "type" : "String",
        "allowedValues" : [ "Install", "Uninstall" ]
        },
        "installationType" : {
        "description" : "(Optional) Specify the type of installation. Uninstall and reinstall: The application is taken offline until the reinstallation process completes. In-place update: The application is available while new or updated files are added to the installation.",
        "type" : "String",
        "allowedValues" : [ "Uninstall and reinstall", "In-place update" ],
        "default" : "Uninstall and reinstall"
        },
        "name" : {
        "description" : "(Required) The package to install/uninstall.",
        "type" : "String",
        "allowedPattern" : "^arn:[a-z0-9][-.a-z0-9]{0,62}:[a-z0-9][-.a-z0-9]{0,62}:([a-z0-9][-.a-z0-9]{0,62})?:([a-z0-9][-.a-z0-9]{0,62})?:(package|document)\\/[a-zA-Z0-9/:.\\-_]{1,128}$|^[a-zA-Z0-9/:.\\-_]{1,128}$"
        },
        "version" : {
        "description" : "(Required) The version of the package to install or uninstall. The system will only attempt to uninstall the version that is currently installed. If no version of the package is installed, the system returns an error.",
        "type" : "String",
        "default" : ""
        },
        "additionalArguments" : {
        "description" : "(Optional) The additional parameters to provide to your install, uninstall, or update scripts.",
        "type" : "StringMap",
        "displayType" : "textarea",
        "default" : { },
        "maxChars" : 4096
        },
        "AutomationAssumeRole" : {
        "type" : "String",
        "description" : "The IAM role required to execute this document, by default use CSD-SystemsManager-AutomationAdministrationRole"
        },
        "bucketName" : {
        "type" : "String",
        "description" : "(Required) Specify the S3 bucket name where the package has been deployed to. This bucket should only consist of the packages and its manifest file"
        },
        "bucketPrefix" : {
        "type" : "String",
        "description" : "(Optional) Specify the S3 prefix (if used) where the package has been deployed to",
        "default" : ""
        },
        "targetKey" : {
        "type" : "String",
        "default" : "InstanceIds",
        "description" : "(Optional) Specify the instances you want to target using Resource Groups, tags or all instances (default option). Refer https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_StartAutomationExecution.html for more details."
        },
        "targetValues" : {
        "type" : "String",
        "default" : "*",
        "description" : "(Optional) Specify the instances you want to target using Resource Groups, tags (use tag: format) or all instances (default option). Refer https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_StartAutomationExecution.html for more details."
        },
        "targetAccounts" : {
        "type" : "StringList"
        },
        "targetRegions" : {
        "type" : "StringList"
        },
        "maxConcurrency" : {
        "type" : "String",
        "default" : "4"
        },
        "maxErrors" : {
        "type" : "String",
        "default" : "4"
        }
    },
    "mainSteps" : [ {
        "name" : "addPackageToDistributor",
        "action" : "aws:executeScript",
        "inputs" : {
        "Runtime" : "python3.7",
        "Handler" : "script_handler",
        "Script": "import sys\nimport boto3\nimport json\nimport botocore\nimport time\n\ndef script_handler(events, context):\n  s3 = boto3.client('s3')\n  org = boto3.client('organizations')\n  \n  executables = []\n  files=[]\n  bucketName = events['bucketName']\n  bucketPrefix = events['bucketPrefix']\n  package = events['name']\n  version = events['version']\n  accountId = events['accountId']\n  region = events['region']\n  targetAccounts = events['targetAccounts']\n  targetRegions = events['targetRegions']\n  packageArns = []\n  \n  for tr in targetRegions:\n    accountList = []\n    ssm = boto3.client('ssm',region_name=tr)\n    \n    packageArns.append('arn:aws:ssm:'+tr+':'+accountId+':document/'+package)\n  \n    #(1) Get package manifest content\n    if not bucketPrefix:\n      manifestFile = \"manifest.json\"\n    else:\n      manifestFile = bucketPrefix+\"/manifest.json\"\n    \n    fileObject = s3.get_object(\n        Bucket=bucketName,\n        Key=manifestFile\n      ) \n    \n    manifestContent = fileObject['Body'].read().decode('utf-8')\n    \n    \n    #(2) Get all the zip files that form part of the package\n    listResponse = s3.list_objects_v2(\n      Bucket=bucketName,\n      StartAfter=bucketPrefix\n    )\n    \n    if listResponse['Contents']:\n      for key in listResponse['Contents']:\n        name = next(iter((key.items())) )\n        \n        executableName = name[1].split(\"/\")\n        for e in executableName:\n          files.append(e)\n    \n    executables = [k for k in files if 'zip' in k]\n    \n    #(3) Add the package to Distributor\n    try:\n      createResponse = ssm.create_document(\n        Content=manifestContent,\n        Attachments=[\n            {\n                'Key': 'SourceUrl',\n                'Values': [\n                    'https://s3.amazonaws.com/'+bucketName+'/'+bucketPrefix,\n                ]\n            },\n        ],\n        Name=package,\n        VersionName=version,\n        DocumentType='Package'\n      )\n  \n    except:\n      documentResponse = ssm.describe_document(\n                Name=package\n              )\n\n      if documentResponse['Document']['VersionName'] == version:\n        print('Document to be updated with name '+ package +' has the same metadata and content as document version provided in request. Proceeding to sharing package with member accounts.')\n\n      else:        \n        print(package+' already exists, creating a new version')\n        \n        update_response = ssm.update_document(\n          Content=manifestContent,\n          Attachments=[\n              {\n                  'Key': 'SourceUrl',\n                  'Values': [\n                      'https://s3.amazonaws.com/'+bucketName+'/'+bucketPrefix,\n                  ]\n              },\n          ],\n          Name=package,\n          VersionName=version,\n          DocumentVersion='$LATEST'\n        )\n        \n        print('Setting ' + version + ' as the default version\\n')\n        \n        \n        update_document_default_version_response = ssm.update_document_default_version(\n          Name=package,\n          DocumentVersion=update_response['DocumentDescription']['DocumentVersion']\n        )\n    \n    \n    #(4) Share package with member accounts\n    accounts_paginator = org.get_paginator('list_accounts_for_parent')\n    ou_paginator = org.get_paginator('list_organizational_units_for_parent')\n    \n    documentResponse = ssm.describe_document(\n      Name=package\n    )\n    \n    if documentResponse:\n      for ta in targetAccounts:\n        if ta.isdigit():\n          acc = str(ta)\n          accountList.append(acc)\n        else:\n          for page in accounts_paginator.paginate(ParentId=ta):\n            for accounts in page['Accounts']:\n              accountList.append(accounts['Id'])\n          for page in ou_paginator.paginate(ParentId=ta):\n            for ou in page['OrganizationalUnits']:\n              for child_ou in accounts_paginator.paginate(ParentId=ou['Id']):\n                for accounts in child_ou['Accounts']:\n                  accountList.append(accounts['Id'])\n      \n      if accountList:\n        removeResponse = ssm.modify_document_permission(\n          Name=package,\n          PermissionType='Share',\n          AccountIdsToRemove=[\n              'all',\n          ]\n        )\n        \n        #To bypass ModifyDocumentPermission API's limit of 20 accounts - https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_ModifyDocumentPermission.html    \n        newAccounts = [accountList[x:x+20] for x in range(0, len(accountList), 20)]\n      \n        for newAccount in newAccounts:\n          additionResponse = ssm.modify_document_permission(\n            Name=package,\n            PermissionType='Share',\n            AccountIdsToAdd=newAccount\n          )\n        \n          if additionResponse['ResponseMetadata']:\n            if additionResponse['ResponseMetadata']['HTTPStatusCode'] == 200:\n              print(f'Successfully modified '+package+' permissions\\n')\n            else:\n              raise Exception(f'There was a problem modifying the permissions of '+package+', check the logs for more details\\n')\n          else:\n            raise Exception(f'There seems to be a problem, check the logs for more details\\n')\n\n      else:\n        raise Exception(f\"No accounts found in the management[parent] account\")\n    else:\n      raise Exception(f\"Cannot find \"+package+\", check the log for more details\")\n    \n    print(package+' has been shared with a total of '+str(len(accountList))+' accounts in ' + tr +'\\n')\n  return {'message': packageArns}",
        "InputPayload" : {
            "bucketName" : "{{ bucketName }}",
            "bucketPrefix" : "{{ bucketPrefix }}",
            "name" : "{{ name }}",
            "version" : "{{ version }}",
            "region" : "{{global:REGION}}",
            "accountId" : "{{global:ACCOUNT_ID}}",
            "targetAccounts" : "{{ targetAccounts }}",
            "targetRegions" : "{{ targetRegions }}"
        }
        },
        "description" : "This step will add the package that you have built and uploaded to S3 to AWS SSM Distributor. Refer to [Create a package](https://docs.aws.amazon.com/systems-manager/latest/userguide/distributor-working-with-packages-create.html#distributor-working-with-packages-create-adv) for more details. This step requires that you complete the first 3 steps including uploading the package and manifest file to a S3 bucket that this document will have access to.",
        "nextStep" : "waitForPackageToBeAddedToDistibutor"
    }, {
        "name" : "waitForPackageToBeAddedToDistibutor",
        "action" : "aws:waitForAwsResourceProperty",
        "inputs" : {
        "Service" : "ssm",
        "Api" : "GetDocument",
        "PropertySelector" : "Status",
        "DesiredValues" : [ "Active" ],
        "Name" : "{{ name }}"
        }
    }, {
        "name" : "invokeCentralizedDistributorMemberDocument",
        "action" : "aws:executeScript",
        "inputs" : {
        "Runtime" : "python3.7",
        "Handler" : "script_handler",
        "Script" : "import sys\nimport boto3\nimport json\nimport botocore\n\ndef script_handler(events, context):\n  client = boto3.client('ssm')\n  \n  automationAssumeRole = events['automationAssumeRole']\n  documentName = 'CSD-DistributeSoftwarePackage'\n  instanceId = events['instanceId']\n  action = events['action']\n  installationType = events['installationType']\n  version = events['version']\n  additionalArguments = events['additionalArguments']\n  targetKey = events['targetKey']\n  targetValues = events['targetValues']\n  targetAccounts = events['targetAccounts']\n  targetRegions = events['targetRegions']\n  maxConcurrency = events['maxConcurrency']\n  maxErrors = events['maxErrors']\n  accountId = events['accountId']\n  package = events['package']\n  distributionDetails = {}\n  \n  distributionDetails['InstanceId'] = [instanceId]\n  distributionDetails['action'] = [action]\n  distributionDetails['installationType'] = [installationType]\n  distributionDetails['AutomationAssumeRole'] = [automationAssumeRole]\n  \n  if not version:\n    print('No version specified')\n  else:\n    distributionDetails['version'] = [version]\n    \n  if not additionalArguments:\n    print('No additional arguments specified')\n  else:\n    distributionDetails['additionalArguments'] = [additionalArguments]\n  \n  \n  for tr in targetRegions:\n    name = 'arn:${AWS::Partition}:ssm:'+tr+':'+accountId+':document/'+package\n    distributionDetails['name'] = [name]\n    response = client.start_automation_execution(\n      DocumentName=documentName,\n      Parameters=distributionDetails,\n      TargetParameterName='InstanceId',\n      Targets=[{'Key':targetKey,'Values':[targetValues]}],\n      TargetLocations=[\n        {\n          'Accounts': targetAccounts,\n          'ExecutionRoleName': 'CSD-SystemsManager-AutomationExecutionRole',\n          'Regions': [tr],\n          'TargetLocationMaxConcurrency': maxConcurrency,\n          'TargetLocationMaxErrors': maxErrors\n        }]\n    )\n          \n    if response['AutomationExecutionId']:\n      status = 'Document has been successfuly invoked. Check AutomationExecutionId - ' + response['AutomationExecutionId'] + ' for more details'\n    else:\n      status = 'Document was not invoked'\n      raise Exception(f'It appears that this step couldn\\'t be completed due to an unknown error. Please check the logs for more details') \n  \n  return {'message': status}",
        "InputPayload" : {
            "instanceId" : "{{ InstanceId }}",
            "action" : "{{ action }}",
            "installationType" : "{{installationType}}",
            "version" : "{{ version }}",
            "additionalArguments" : "{{ additionalArguments }}",
            "targetKey" : "{{ targetKey }}",
            "targetValues" : "{{ targetValues }}",
            "targetAccounts" : "{{ targetAccounts }}",
            "targetRegions" : "{{ targetRegions }}",
            "maxConcurrency" : "{{ maxConcurrency }}",
            "maxErrors" : "{{ maxErrors }}",
            "automationAssumeRole" : "{{ AutomationAssumeRole }}",
            "accountId" : "{{global:ACCOUNT_ID}}",
            "package" : "{{ name }}"
        }
        },
        "isEnd" : true
    } ]
    }