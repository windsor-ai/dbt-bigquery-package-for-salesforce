# Field Mapping Reference - Windsor.ai Integration

## Overview

This document provides a reference for all field mappings used in the dbt Salesforce Campaign Funnel package when integrated with Windsor.ai. Windsor.ai automatically transforms Salesforce field names into a standardized format, and this package is configured to work with that schema.

You can find a complete list of available Salesforce fields through Windsor.ai at: https://windsor.ai/data-field/salesforce/

## Windsor.ai Field Transformation

Windsor.ai transforms native Salesforce field names according to these patterns:
- **Object prefixes**: Fields are prefixed with the object name (e.g., `campaign_`, `lead_`, `contact_`)
- **Standardized naming**: CamelCase becomes snake_case (e.g., `CreatedDate` → `created_date`)
- **Consistent types**: Data types are standardized for BigQuery compatibility

## Configuration

Field mappings are configured in your `dbt_project.yml` file under the `vars` section. The defaults are set to match Windsor.ai's standard Salesforce schema, but you can override them if needed.

## Campaign Fields (Windsor.ai Schema)

### Basic Campaign Information
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `campaigns_id_field` | `campaign_id` | `campaign_id` | `Id` | Unique identifier for campaigns |
| `campaigns_name_field` | `campaign_name` | `campaign_name` | `Name` | Campaign display name |
| `campaigns_type_field` | `campaign_type` | `campaign_type` | `Type` | Campaign type (Email, Webinar, etc.) |
| `campaigns_status_field` | `campaign_status` | `campaign_status` | `Status` | Campaign status (Planned, Active, etc.) |
| `campaigns_description_field` | `campaign_description` | `campaign_description` | `Description` | Campaign description text |

### Campaign Dates
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `campaigns_created_date_field` | `campaign_created_date` | `campaign_created_date` | `CreatedDate` | When campaign was created |
| `campaigns_start_date_field` | `campaign_start_date` | `campaign_start_date` | `StartDate` | Campaign start date |
| `campaigns_end_date_field` | `campaign_end_date` | `campaign_end_date` | `EndDate` | Campaign end date |

### Campaign Financial Data
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `campaigns_actual_cost_field` | `campaign_actual_cost` | `campaign_actual_cost` | `ActualCost` | Actual money spent on campaign |
| `campaigns_budgeted_cost_field` | `campaign_budgeted_cost` | `campaign_budgeted_cost` | `BudgetedCost` | Budgeted campaign cost |
| `campaigns_expected_revenue_field` | `campaign_expected_revenue` | `campaign_expected_revenue` | `ExpectedRevenue` | Expected revenue from campaign |

### Campaign Status & Control
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `campaigns_is_active_field` | `campaign_is_active` | `campaign_is_active` | `IsActive` | Whether campaign is active |
| `campaigns_is_deleted_field` | `campaign_is_deleted` | `campaign_is_deleted` | `IsDeleted` | Soft delete flag |
| `campaigns_owner_id_field` | `campaign_owner_id` | `campaign_owner_id` | `OwnerId` | Campaign owner user ID |
| `campaigns_parent_id_field` | `campaign_parent_id` | `campaign_parent_id` | `ParentId` | Parent campaign (for hierarchies) |

## Lead Fields (Windsor.ai Schema)

### Basic Lead Information
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `leads_id_field` | `lead_id` | `lead_id` | `Id` | Unique lead identifier |
| `leads_first_name_field` | `lead_first_name` | `lead_first_name` | `FirstName` | Lead's first name |
| `leads_last_name_field` | `lead_last_name` | `lead_last_name` | `LastName` | Lead's last name |
| `leads_name_field` | `lead_name` | `lead_name` | `Name` | Lead's full name |
| `leads_email_field` | `lead_email` | `lead_email` | `Email` | Primary email address |
| `leads_email_fallback_field` | `email` | `email` | `Email` | Fallback email field |
| `leads_company_field` | `lead_company` | `lead_company` | `Company` | Company name |
| `leads_title_field` | `lead_title` | `lead_title` | `Title` | Job title |
| `leads_phone_field` | `lead_phone` | `lead_phone` | `Phone` | Phone number |

### Lead Status & Source
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `leads_status_field` | `lead_status` | `lead_status` | `Status` | Lead status (Open, Qualified, etc.) |
| `leads_source_field` | `lead_lead_source` | `lead_lead_source` | `LeadSource` | Lead source |
| `leads_rating_field` | `lead_rating` | `lead_rating` | `Rating` | Lead quality rating |

### Lead Conversion Data
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `leads_converted_date_field` | `lead_converted_date` | `lead_converted_date` | `ConvertedDate` | When lead was converted |
| `leads_converted_contact_id_field` | `lead_converted_contact_id` | `lead_converted_contact_id` | `ConvertedContactId` | Resulting contact ID |
| `leads_converted_opportunity_id_field` | `lead_converted_opportunity_id` | `lead_converted_opportunity_id` | `ConvertedOpportunityId` | Resulting opportunity ID |
| `leads_converted_account_id_field` | `lead_converted_account_id` | `lead_converted_account_id` | `ConvertedAccountId` | Resulting account ID |
| `leads_is_converted_field` | `lead_is_converted` | `lead_is_converted` | `IsConverted` | Conversion status flag |

### Lead Dates & Ownership
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `leads_created_date_field` | `lead_created_date` | `lead_created_date` | `CreatedDate` | Lead creation timestamp |
| `leads_owner_id_field` | `lead_owner_id` | `lead_owner_id` | `OwnerId` | Lead owner user ID |
| `leads_is_deleted_field` | `lead_is_deleted` | `lead_is_deleted` | `IsDeleted` | Soft delete flag |

## Contact Fields (Windsor.ai Schema)

### Basic Contact Information
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `contacts_id_field` | `contact_id` | `contact_id` | `Id` | Unique contact identifier |
| `contacts_first_name_field` | `contact_firstname` | `contact_firstname` | `FirstName` | Contact's first name |
| `contacts_last_name_field` | `contact_lastname` | `contact_lastname` | `LastName` | Contact's last name |
| `contacts_name_field` | `contact_name` | `contact_name` | `Name` | Full name |
| `contacts_email_field` | `contact_email` | `contact_email` | `Email` | Email address |
| `contacts_phone_field` | `contact_phone` | `contact_phone` | `Phone` | Primary phone |
| `contacts_mobile_phone_field` | `contact_mobilephone` | `contact_mobilephone` | `MobilePhone` | Mobile phone |

### Contact Professional Information
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `contacts_title_field` | `contact_title` | `contact_title` | `Title` | Job title |
| `contacts_department_field` | `contact_department` | `contact_department` | `Department` | Department |
| `contacts_account_id_field` | `contact_accountid` | `contact_accountid` | `AccountId` | Associated account ID |
| `contacts_lead_source_field` | `contact_leadsource` | `contact_leadsource` | `LeadSource` | Original lead source |

### Contact Dates
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `contacts_created_date_field` | `contact_createddate` | `contact_createddate` | `CreatedDate` | Contact creation date |
| `contacts_last_modified_date_field` | `contact_lastmodifieddate` | `contact_lastmodifieddate` | `LastModifiedDate` | Last modified date |
| `contacts_owner_id_field` | `contact_ownerid` | `contact_ownerid` | `OwnerId` | Contact owner |
| `contacts_is_deleted_field` | `contact_isdeleted` | `contact_isdeleted` | `IsDeleted` | Soft delete flag |

## Campaign Member Fields (Windsor.ai Schema)

### Campaign Member Identity
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `campaign_members_id_field` | `campaignmember_id` | `campaignmember_id` | `Id` | Unique campaign member ID |
| `campaign_members_campaign_id_field` | `campaignmember_campaign_id` | `campaignmember_campaign_id` | `CampaignId` | Associated campaign |
| `campaign_members_lead_id_field` | `campaignmember_lead_id` | `campaignmember_lead_id` | `LeadId` | Associated lead (if applicable) |
| `campaign_members_contact_id_field` | `campaignmember_contact_id` | `campaignmember_contact_id` | `ContactId` | Associated contact (if applicable) |
| `campaign_members_lead_or_contact_id_field` | `campaignmember_lead_or_contact_id` | `campaignmember_lead_or_contact_id` | `LeadOrContactId` | Unified reference |

### Campaign Member Status & Response
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `campaign_members_type_field` | `campaignmember_type` | `campaignmember_type` | `Type` | Member type (Lead/Contact) |
| `campaign_members_status_field` | `campaignmember_status` | `campaignmember_status` | `Status` | Member status |
| `campaign_members_has_responded_field` | `campaignmember_has_responded` | `campaignmember_has_responded` | `HasResponded` | Response flag |
| `campaign_members_first_responded_date_field` | `campaignmember_first_responded_date` | `campaignmember_first_responded_date` | `FirstRespondedDate` | First response date |

### Campaign Member Dates
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `campaign_members_created_date_field` | `campaignmember_createddate` | `campaignmember_createddate` | `CreatedDate` | Member creation date |
| `campaign_members_last_modified_date_field` | `campaignmember_lastmodifieddate` | `campaignmember_lastmodifieddate` | `LastModifiedDate` | Last modified |

## Opportunity Fields (Windsor.ai Schema)

### Basic Opportunity Information
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `opportunities_id_field` | `opportunity_id` | `opportunity_id` | `Id` | Unique opportunity ID |
| `opportunities_name_field` | `opportunity_name` | `opportunity_name` | `Name` | Opportunity name |
| `opportunities_description_field` | `opportunity_description` | `opportunity_description` | `Description` | Description |
| `opportunities_type_field` | `opportunity_type` | `opportunity_type` | `Type` | Opportunity type |

### Opportunity Relationships
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `opportunities_campaign_id_field` | `opportunity_campaign_id` | `opportunity_campaign_id` | `CampaignId` | Primary campaign source |
| `opportunities_account_id_field` | `opportunity_account_id` | `opportunity_account_id` | `AccountId` | Associated account |
| `opportunities_contact_id_field` | `opportunity_contact_id` | `opportunity_contact_id` | `ContactId` | Primary contact |

### Opportunity Status & Financial
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `opportunities_stage_name_field` | `opportunity_stage_name` | `opportunity_stage_name` | `StageName` | Current stage |
| `opportunities_is_closed_field` | `opportunity_is_closed` | `opportunity_is_closed` | `IsClosed` | Closed status |
| `opportunities_is_won_field` | `opportunity_is_won` | `opportunity_is_won` | `IsWon` | Won status |
| `opportunities_amount_field` | `opportunity_amount` | `opportunity_amount` | `Amount` | Opportunity value |
| `opportunities_probability_field` | `opportunity_probability` | `opportunity_probability` | `Probability` | Win probability (0-100) |

### Opportunity Dates
| Variable Name | Default Value | Windsor.ai Field | Salesforce Source | Description |
|---------------|---------------|------------------|-------------------|-------------|
| `opportunities_created_date_field` | `opportunity_created_date` | `opportunity_created_date` | `CreatedDate` | Creation date |
| `opportunities_created_date_fallback_field` | `opportunity_createddate` | `opportunity_createddate` | `CreatedDate` | Fallback creation field |
| `opportunities_close_date_field` | `opportunity_close_date` | `opportunity_close_date` | `CloseDate` | Expected/actual close date |
| `opportunities_last_modified_date_field` | `opportunity_last_modified_date` | `opportunity_last_modified_date` | `LastModifiedDate` | Last modified |
| `opportunities_owner_id_field` | `opportunity_owner_id` | `opportunity_owner_id` | `OwnerId` | Opportunity owner |
| `opportunities_is_deleted_field` | `opportunity_is_deleted` | `opportunity_is_deleted` | `IsDeleted` | Soft delete flag |

## Windsor.ai Source Table Names

These are the expected BigQuery table names created by Windsor.ai:

```yaml
sources:
  - name: salesforce
    tables:
      - name: campaigns           # Windsor.ai: salesforce_campaigns
      - name: leads               # Windsor.ai: salesforce_leads  
      - name: contacts            # Windsor.ai: salesforce_contacts
      - name: campaign_members    # Windsor.ai: salesforce_campaign_members
      - name: opportunities       # Windsor.ai: salesforce_opportunities
```

## Usage Examples

### Standard Windsor.ai Configuration
```yaml
vars:
  # Date range for processing
  start_date: '2020-01-01'
  end_date: '2024-12-31'
  
  # Data quality filters
  exclude_test_campaigns: true
  exclude_deleted_records: true
  
  # Currency settings
  target_currency: 'USD'
  
  # Windsor.ai field mappings (defaults work for most cases)
  campaigns_id_field: 'campaign_id'
  campaigns_name_field: 'campaign_name'
  leads_email_field: 'lead_email'
```

### Custom Field Override (if needed)
```yaml
vars:
  # Only override if Windsor.ai provides different field names
  # or if you have custom fields mapped
  opportunities_stage_name_field: 'opportunity_stagename'
  campaigns_actual_cost_field: 'campaign_actualcost'
```

## Windsor.ai Data Types

Windsor.ai standardizes Salesforce data types for BigQuery:

| Salesforce Type | Windsor.ai BigQuery Type | Notes |
|-----------------|--------------------------|-------|
| `Id` | `STRING` | All IDs as strings |
| `Text` | `STRING` | Text fields |
| `Date` | `DATE` | Date only |
| `DateTime` | `TIMESTAMP` | Full timestamp |
| `Number` | `NUMERIC` | Decimal numbers |
| `Currency` | `NUMERIC` | Financial values |
| `Boolean` | `BOOLEAN` | True/false values |
| `Picklist` | `STRING` | Enum values |

## Required Fields for Package Functionality

### Minimum Required Fields
These fields must be present in your Windsor.ai integration:

**Campaigns**:
- `campaign_id`, `campaign_name`, `campaign_status`, `campaign_created_date`

**Leads**:
- `lead_id`, `lead_email`, `lead_status`, `lead_created_date`

**Contacts**:
- `contact_id`, `contact_email`, `contact_createddate`

**Campaign Members**:
- `campaignmember_id`, `campaignmember_campaign_id`, `campaignmember_createddate`

**Opportunities**:
- `opportunity_id`, `opportunity_name`, `opportunity_stage_name`, `opportunity_created_date`

## Troubleshooting Windsor.ai Integration

### Common Issues

1. **Table not found**: Verify Windsor.ai has created the expected table names in your BigQuery project
2. **Field missing**: Check Windsor.ai field mapping configuration in your connector
3. **Data type mismatch**: Windsor.ai handles type conversion; if issues persist, check source data quality
4. **Date parsing**: Windsor.ai standardizes date formats; package handles various timestamp formats

### Validation
```bash
# Test Windsor.ai source connections
dbt source freshness

# Validate field mappings work
dbt run --select stg_salesforce

# Run all data quality tests
dbt test
```