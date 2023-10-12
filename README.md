**Overview**


**Centralized-distribution-managment in an AWS Organization**


  This Solution will demonstrate how you can build a solution using Terraform for organizations with a large number of instances. You can use this solution to simplify the process of managing the installation of software and 
  execute any specific scripts on the instances across all of your member accounts within an AWS Organization with minimal effort.

  This solution works for Amazon/Linux/window instances managed by AWS System manager. This solution can be used by administration team for installing security scanning softwares like CrowdStrike, SentinelOne & Monitoring 
  Tool CloudWatch agent , Datadog agent, AppDynamics agent.



**Prerequisites**

The following prerequisites need to be completed to deploy this solution.

-A Distributor package  with the software to be installed

-Terraform v1.4.6+ Configuration. 

-SSM managed EC2 Instances with basic permission to S3 in target account

-AWS Control Tower Landing Zone Setup

-Account Factory for Terraform (Optional) 



**Architecture**


This terraform code will deploy below architeture

<img width="1199" alt="Architecture diagram" src="https://github.com/aws-samples/aws-organization-centralised-package-distribution/assets/65273458/028e2917-a9d2-47f8-9a99-91f7129196a7">







**Deployment**

To deploy the solution using Terraform, we will use Account Factory for Terraform(AFT) that is already configured. You can also deploy this solution without using AFT by running Terraform command in the Account Customizations folder.

This Terraform script deploys the following resources:

 **IAM Role & IAM policies**:
- SystemsManager-AutomationExecutionRole  : This role gives the user permission to run automations in the targeted accounts.
- SystemsManager-AutomationAdministrationRole : This role gives the user permission to run automations in multiple accounts and OUs.

   **Zip Files & manifest.json for Package**:
-  The foundation of package  is at least one .zip file of software or installable assets.
-  JSON manifest includes pointers to your package code files
  
  **S3 Bucket**:
-  Amazon Simple Storage Service(S3) used to Centralized & securely store the distributed package that is shared across organization,
  
  **AWS System Manager Documents**: 
-  DistributeSoftwarePackage: This document  contains the logic to distribute the software package to every target instance in the member accounts.
-  AddSoftwarePackageToDistributor: This document contains the logic to package the installable software assets and add it to System Manager Automation.

  **AWS System Manager Association**: 
-  System Manager Association will use to Invoking the solution



  
**Solution Workflow**

- As per above solution architecture diagram , the solution workflow explained below (each step below corresponds to step in architecture diagram)
- By running the solution from a centralized account, we will upload our packages or software along with deployment steps to AWS S3,
- the solution makes your customized package available on Systems Manager Documents under the Owned by me tab that creates and invokes by a  State Manager association across the organization,
- The association specifies that the software package must be installed and running on a managed node before it can be installed on the Target node.
- The association instructs State Manager to install the package, then it will install on the Target node.
- For any subsequent installations or changes, users can use the same SSM association to run it at periodic intervals or manually from a single place to perform deployments across accounts 
- This solution uses the management account within AWS Organizations, but you can also designate an account (delegated administrator) to manage this on behalf of the organization by Register a delegated administrator.



**Validate execution in System Manager console**



**Validate SSM Documents creation in SSM Console**:

- Open the Systems Manager console, from the left navigation pane choose  Documents under the Shared Resources
- Click on Owned by me tab,
- You should see the DistributeSoftwarePackage and AddSoftwarePackageToDistributor packages

**Validating the execution ran successfully**:

- Open the Systems Manager console, from the left navigation pane choose Automation
- In Automation executions you should see the most recent execution of both AddSoftwarePackageToDistributor and DistributeSoftwarePackage
- Click on  Execution ID to validate if they were completed successfully

**Validating the package deployed to the targeted member account instances**

- As per above solution architecture diagram
- Navigate to the Systems Manager dashboard and select Run Command in the left pane, Under Command history, you should be able to see every invocation and their status.
- Click any Command ID, you should be able to see the execution history on each target instances
- Select the Instance ID for the command output. Check the Output section



**Security**

See [SECURITY](./SECURITY.md) for more information.



**License**

This library is licensed under the MIT-0 License. See the Licence [LICENCE](./LICENSE)
 file.
