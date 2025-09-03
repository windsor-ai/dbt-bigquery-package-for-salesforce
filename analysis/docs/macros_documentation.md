# Macros Documentation

## Overview

This dbt package includes utility macros that standardize common Salesforce data transformations. These macros ensure consistent data cleaning, type conversion, and validation across all models while handling the nuances of Windsor.ai's Salesforce integration.

## Available Macros

### 1. `clean_boolean(field_name)`

**Purpose**: Convert Salesforce string boolean values to actual boolean type

**Usage**:
```sql
select {{ clean_boolean('is_active') }} as is_active_clean
```

**Input**: 
- Salesforce boolean fields that come through Windsor.ai as strings ('true', 'false')
- Handles case variations and null values

**Output**: 
- `true` for 'true' (case insensitive)
- `false` for 'false' (case insensitive)  
- `null` for any other value

**Example**:
```sql
-- Input data from Windsor.ai
| is_active | 
|-----------|
| 'true'    |
| 'True'    |
| 'false'   |
| 'FALSE'   |
| null      |
| ''        |

-- After clean_boolean('is_active')
| is_active_clean |
|-----------------|
| true            |
| true            |
| false           |
| false           |
| null            |
| null            |
```

---

### 2. `clean_email(field_name)`

**Purpose**: Clean and validate email addresses with basic format checking

**Usage**:
```sql
select {{ clean_email('email_address') }} as email_clean
```

**Input**: Email fields that may contain:
- Leading/trailing whitespace
- Mixed case
- Invalid formats
- Empty strings

**Output**: 
- Lowercased, trimmed email for valid addresses
- `null` for invalid or empty emails

**Validation Rules**:
- Must contain '@' symbol
- Must contain '.' symbol
- Must not be empty after trimming

**Example**:
```sql
-- Input data
| email_address        |
|---------------------|
| 'John@Example.COM'  |
| '  mary@test.com  ' |
| 'invalid-email'     |
| 'test@'             |
| ''                  |
| null                |

-- After clean_email('email_address')
| email_clean         |
|---------------------|
| 'john@example.com'  |
| 'mary@test.com'     |
| null                |
| null                |
| null                |
| null                |
```

---

### 3. `safe_date_parse(field_reference, output_type)`

**Purpose**: Robust date parsing with error handling for multiple formats

**Usage**:
```sql
select {{ safe_date_parse('created_date', 'timestamp') }} as created_at
select {{ safe_date_parse('start_date', 'date') }} as start_date_clean
```

**Parameters**:
- `field_reference`: The field to parse
- `output_type`: Target type (`'date'`, `'timestamp'`, `'datetime'`)

**Input**: Date/timestamp fields from Windsor.ai that may be:
- Various string formats
- Already parsed timestamps
- Null or empty values

**Output**: 
- Properly typed date/timestamp values
- `null` for invalid or empty dates

**Example**:
```sql
-- Input data
| created_date         |
|----------------------|
| '2024-01-15'        |
| '2024-01-15 10:30'  |
| ''                  |
| null                |

-- After safe_date_parse('created_date', 'date')
| created_at          |
|---------------------|
| 2024-01-15          |
| 2024-01-15          |
| null                |
| null                |
```

---

### 4. `calculate_days_between(start_date, end_date)`

**Purpose**: Calculate days between two dates with null safety

**Usage**:
```sql
select {{ calculate_days_between('lead_created_date', 'converted_date') }} as days_to_conversion
```

**Input**: Two date/timestamp fields

**Output**: 
- Integer number of days between dates
- `null` if either date is null or invalid

**Features**:
- Automatically handles date parsing using `safe_date_parse`
- Uses BigQuery's `DATE_DIFF` function
- Always returns positive values (end_date - start_date)

**Example**:
```sql
-- Input data
| start_date  | end_date    |
|-------------|-------------|
| '2024-01-01'| '2024-01-10'|
| '2024-01-15'| '2024-01-15'|
| '2024-01-01'| null        |
| null        | '2024-01-10'|

-- After calculate_days_between('start_date', 'end_date')
| days_between |
|-------------|
| 9           |
| 0           |
| null        |
| null        |
```

---

### 5. `clean_currency(field_name, min_value)`

**Purpose**: Clean and validate currency/numeric fields with range checking

**Usage**:
```sql
select {{ clean_currency('amount', min_value=0) }} as amount_clean
select {{ clean_currency('budget') }} as budget_clean  -- No minimum
```

**Parameters**:
- `field_name`: The numeric field to clean
- `min_value`: Optional minimum value validation

**Input**: Numeric fields from Windsor.ai that may be:
- String representations of numbers
- Already numeric
- Negative values (when not allowed)
- Null or empty

**Output**: 
- Properly typed numeric values
- `null` for invalid values or those below minimum

**Example**:
```sql
-- Input data
| amount    |
|-----------|
| '1000.50' |
| '0'       |
| '-100'    |
| 'invalid' |
| null      |

-- After clean_currency('amount', min_value=0)
| amount_clean |
|-------------|
| 1000.50     |
| 0.00        |
| null        |
| null        |
| null        |
```

---

### 6. `clean_phone(field_name)`

**Purpose**: Standardize phone number format by removing non-numeric characters

**Usage**:
```sql
select {{ clean_phone('phone_number') }} as phone_clean
```

**Input**: Phone number fields with various formats

**Output**: 
- Digits-only string
- `null` for empty or null values

**Features**:
- Removes all non-digit characters using regex
- Preserves only 0-9 digits
- Handles international formats

**Example**:
```sql
-- Input data
| phone_number      |
|-------------------|
| '(555) 123-4567'  |
| '+1-555-123-4567' |
| '555.123.4567'    |
| 'abc'             |
| null              |

-- After clean_phone('phone_number')
| phone_clean       |
|-------------------|
| '5551234567'      |
| '15551234567'     |
| '5551234567'      |
| ''                |
| null              |
```

---

### 7. `parse_date_with_format(field_name, date_format)`

**Purpose**: Parse date strings with specific format patterns

**Usage**:
```sql
select {{ parse_date_with_format('custom_date', '%Y-%m-%d') }} as date_parsed
```

**Parameters**:
- `field_name`: Date field to parse
- `date_format`: Expected date format pattern (default: `'%Y-%m-%d'`)

**Input**: Date strings in specific formats

**Output**: 
- Parsed DATE values
- Falls back to `SAFE_CAST` if format parsing fails
- `null` for invalid dates

**Common Date Formats**:
- `'%Y-%m-%d'`: 2024-01-15
- `'%m/%d/%Y'`: 01/15/2024  
- `'%d-%b-%Y'`: 15-Jan-2024

**Example**:
```sql
-- Input data with custom format
| custom_date |
|-------------|
| '01/15/2024'|
| '12/31/2023'|
| 'invalid'   |

-- After parse_date_with_format('custom_date', '%m/%d/%Y')
| date_parsed |
|-------------|
| 2024-01-15  |
| 2023-12-31  |
| null        |
```

---

### 8. `coalesce_email_fields(primary_field, fallback_field)`

**Purpose**: Handle multiple email field variations with fallback

**Usage**:
```sql
select {{ coalesce_email_fields('primary_email', 'secondary_email') }} as best_email
select {{ coalesce_email_fields('email_field') }} as email_clean  -- No fallback
```

**Parameters**:
- `primary_field`: Primary email field
- `fallback_field`: Optional fallback email field

**Input**: Multiple email fields where primary might be empty

**Output**: 
- First valid email found after cleaning
- `null` if no valid email in either field

**Features**:
- Applies `clean_email` macro to both fields
- Uses `COALESCE` to return first non-null valid email
- Common pattern for Windsor.ai data where fields might vary

**Example**:
```sql
-- Input data
| primary_email    | secondary_email  |
|------------------|------------------|
| 'john@test.com'  | 'john@work.com'  |
| null             | 'mary@test.com'  |
| 'invalid'        | 'valid@test.com' |
| null             | null             |

-- After coalesce_email_fields('primary_email', 'secondary_email')
| best_email       |
|------------------|
| 'john@test.com'  |
| 'mary@test.com'  |
| 'valid@test.com' |
| null             |
```

## Macro Usage Patterns

### In Staging Models

```sql
-- models/staging/salesforce/stg_salesforce__leads.sql
select
    lead_id,
    {{ clean_email('lead_email') }} as email,
    {{ clean_boolean('is_converted') }} as is_converted,
    {{ safe_date_parse('created_date', 'timestamp') }} as created_at,
    {{ calculate_days_between('created_date', 'converted_date') }} as days_to_conversion,
    {{ clean_currency('annual_revenue', min_value=0) }} as annual_revenue,
    {{ clean_phone('phone') }} as phone_clean
from {{ source('salesforce', 'leads') }}
```

### In Intermediate Models

```sql
-- models/intermediate/salesforce/int_salesforce__lead_journey.sql
select
    *,
    {{ calculate_days_between('lead_created_at', 'first_campaign_touch_at') }} as days_lead_to_campaign,
    {{ calculate_days_between('first_campaign_touch_at', 'converted_date') }} as days_campaign_to_conversion
from {{ ref('stg_salesforce__leads') }}
```

### Complex Field Handling

```sql
-- Handle multiple date formats and email variations
select
    lead_id,
    {{ coalesce_email_fields('lead_email', 'email') }} as primary_email,
    {{ parse_date_with_format('custom_date_field', '%m/%d/%Y') }} as custom_date,
    case 
        when {{ clean_currency('budget', min_value=1) }} is not null 
        then 'Has Budget'
        else 'No Budget'
    end as budget_status
from {{ source('salesforce', 'leads') }}
```

## Best Practices

### 1. Consistent Usage
- Always use these macros for their respective data types
- Apply macros in staging models for consistency
- Don't mix raw field access with macro usage

### 2. Error Handling
- Macros handle null values gracefully
- Invalid data becomes null rather than causing errors
- Use `SAFE_CAST` patterns throughout

### 3. Performance Considerations
- Macros generate efficient SQL
- BigQuery optimizes the resulting expressions
- Consider indexing/clustering on cleaned fields

### 4. Testing Integration
- Test both raw and cleaned fields
- Validate macro outputs with custom tests
- Use `dbt_utils.not_null_proportion` for quality checks

## Custom Tests for Macro Outputs

```sql
-- tests/assert_email_cleaning_works.sql
select *
from {{ ref('stg_salesforce__leads') }}
where email is not null 
  and (email not like '%@%' or email != lower(email))

-- tests/assert_date_parsing_works.sql  
select *
from {{ ref('stg_salesforce__campaigns') }}
where created_at is not null
  and extract(year from created_at) < 1990

-- tests/assert_currency_cleaning_works.sql
select *
from {{ ref('stg_salesforce__campaigns') }}  
where actual_cost is not null
  and actual_cost < 0
```

## Troubleshooting

### Common Issues

1. **Date Parsing Failures**:
   - Check input date formats in Windsor.ai data
   - Use `parse_date_with_format` for custom formats
   - Verify timezone handling

2. **Email Validation Too Strict**:
   - Modify `clean_email` macro if needed
   - Consider business rules for email validation
   - Test with your actual data patterns

3. **Currency/Numeric Issues**:
   - Check for currency symbols in source data
   - Validate minimum value requirements
   - Consider decimal precision needs

4. **Phone Number Variations**:
   - Review international number formats
   - Adjust regex pattern if needed
   - Consider preserving formatting for display

### Debugging Macro Output

```sql
-- Debug macro transformations
select 
    raw_field,
    {{ clean_email('raw_field') }} as cleaned_field,
    case 
        when raw_field is null then 'null_input'
        when {{ clean_email('raw_field') }} is null then 'invalid_format'
        else 'valid'
    end as cleaning_result
from my_table
where raw_field is not null
```