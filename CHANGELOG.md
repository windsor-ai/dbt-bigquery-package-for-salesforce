# Changelog

All notable changes to this dbt package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security

## [1.0.0] - 2025-09-03

### Added
- **Staging Models**: Complete data cleaning and standardization for all Salesforce objects
  - `stg_salesforce__campaigns` - Campaign master data with consistent field naming
  - `stg_salesforce__leads` - Lead information with safe casting and null handling
  - `stg_salesforce__contacts` - Contact records with account relationships
  - `stg_salesforce__campaign_members` - Campaign membership associations
  - `stg_salesforce__opportunities` - Opportunity pipeline data with stage information

- **Intermediate Models**: Business logic and relationship modeling
  - `int_salesforce__lead_journey` - Lead progression tracking with conversion timing
  - `int_salesforce__campaign_performance` - Campaign performance metrics and ROI calculations
  - `int_salesforce__contact_touchpoints` - Multi-touch interaction history

- **Marts Models**: Analytics-ready tables optimized for BI consumption
  - `salesforce__campaign_lead_funnel` - Complete funnel analysis with conversion metrics
  - `salesforce__campaign_attribution_summary` - Multi-touch attribution reporting

- **Utility Macros**: Reusable data transformation macros
  - `clean_boolean()` - Convert string booleans to proper boolean type
  - `clean_email()` - Standardize and validate email addresses
  - `safe_date_parse()` - Robust date parsing with error handling
  - `calculate_days_between()` - Date difference calculations
  - `clean_currency()` - Numeric/currency field validation
  - `clean_phone()` - Phone number standardization

- **Configuration Options**:
  - Comprehensive field mapping variables for custom Salesforce org schemas
  - Date range filtering for processing control
  - Model enablement/disablement toggles
  - Performance optimization settings
  - Picklist value configuration
  - Database and schema customization

- **Data Quality Framework**:
  - Built-in uniqueness tests for all primary keys
  - Referential integrity tests between related tables
  - Data validation tests for email formats, date ranges, and picklist values
  - Business logic tests for Salesforce-specific rules
  - Completeness tests for required fields

- **BigQuery Optimizations**:
  - Table partitioning by date fields for better query performance
  - Clustering by frequently filtered columns
  - Incremental materialization strategies for large datasets

- **Documentation**:
  - Comprehensive field mapping documentation
  - Package capabilities guide
  - Macro usage examples and documentation

### Security
- Safe casting implemented for all data type conversions
- Input validation for all user-configurable field mappings
- Secure handling of sensitive fields (emails, phone numbers)