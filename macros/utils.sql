{#
  Utility macros for common Salesforce data transformations
  These macros standardize repetitive patterns across staging models
#}

{# 
  Macro: clean_boolean
  Purpose: Convert Salesforce string boolean values to actual boolean type
  Usage: {{ clean_boolean('field_name') }}
  Handles: 'true'/'false' strings, null values, and case variations
#}
{% macro clean_boolean(field_name) %}
  case 
    when lower({{ field_name }}) = 'true' then true
    when lower({{ field_name }}) = 'false' then false
    else null
  end
{% endmacro %}

{# 
  Macro: clean_email
  Purpose: Clean and validate email addresses with basic format checking
  Usage: {{ clean_email('email_field') }}
  Features: Trims whitespace, lowercases, validates @ symbol presence
#}
{% macro clean_email(field_name) %}
  case 
    when {{ field_name }} is not null 
      and trim({{ field_name }}) != ''
      and {{ field_name }} like '%@%'
      and {{ field_name }} like '%.%'
    then lower(trim({{ field_name }}))
    else null
  end
{% endmacro %}

{# 
  Macro: safe_date_parse
  Purpose: Robust date parsing with error handling for multiple formats
  Usage: {{ safe_date_parse('date_field', 'timestamp') }}
  Supports: 'date', 'timestamp', 'datetime' output types
#}
{% macro safe_date_parse(field_reference, output_type='timestamp') %}
  {% if output_type == 'date' %}
    case 
      when {{ field_reference }} is not null 
           and trim(cast({{ field_reference }} as string)) != ''
      then safe_cast({{ field_reference }} as date)
      else null
    end
  {% elif output_type == 'timestamp' %}
    case 
      when {{ field_reference }} is not null 
           and trim(cast({{ field_reference }} as string)) != ''
      then safe_cast({{ field_reference }} as timestamp)
      else null
    end
  {% else %}
    safe_cast({{ field_reference }} as {{ output_type }})
  {% endif %}
{% endmacro %}

{# 
  Macro: calculate_days_between
  Purpose: Calculate days between two dates with null safety
  Usage: {{ calculate_days_between('start_date', 'end_date') }}
  Returns: Integer days or null if either date is null
#}
{% macro calculate_days_between(start_date, end_date) %}
  case 
    when {{ safe_date_parse(start_date, 'date') }} is not null 
      and {{ safe_date_parse(end_date, 'date') }} is not null
    then date_diff(
      {{ safe_date_parse(end_date, 'date') }},
      {{ safe_date_parse(start_date, 'date') }},
      day
    )
    else null
  end
{% endmacro %}

{# 
  Macro: clean_currency
  Purpose: Clean and validate currency/numeric fields with range checking
  Usage: {{ clean_currency('amount_field', min_value=0) }}
  Features: SAFE_CAST with optional minimum value validation
#}
{% macro clean_currency(field_name, min_value=none) %}
  {% if min_value is not none %}
    case 
      when safe_cast({{ field_name }} as numeric) is not null
        and safe_cast({{ field_name }} as numeric) >= {{ min_value }}
      then safe_cast({{ field_name }} as numeric)
      else null
    end
  {% else %}
    safe_cast({{ field_name }} as numeric)
  {% endif %}
{% endmacro %}

{# 
  Macro: clean_phone
  Purpose: Standardize phone number format by removing non-numeric characters
  Usage: {{ clean_phone('phone_field') }}
  Returns: Digits only or null if invalid
#}
{% macro clean_phone(field_name) %}
  case 
    when {{ field_name }} is not null and trim({{ field_name }}) != ''
    then regexp_replace({{ field_name }}, r'[^0-9]', '')
    else null
  end
{% endmacro %}

{# 
  Macro: parse_date_with_format
  Purpose: Parse date strings with specific format patterns
  Usage: {{ parse_date_with_format('date_field', '%Y-%m-%d') }}
  Fallback: Uses SAFE_CAST if format parsing fails
#}
{% macro parse_date_with_format(field_name, date_format='%Y-%m-%d') %}
  case 
    when {{ field_name }} is not null and {{ field_name }} != ''
    then coalesce(
      safe.parse_date('{{ date_format }}', {{ field_name }}),
      safe_cast({{ field_name }} as date)
    )
    else null
  end
{% endmacro %}

{# 
  Macro: coalesce_email_fields
  Purpose: Handle multiple email field variations with fallback
  Usage: {{ coalesce_email_fields('primary_email', 'secondary_email') }}
  Returns: First valid email found or null
#}
{% macro coalesce_email_fields(primary_field, fallback_field=none) %}
  {% if fallback_field %}
    coalesce(
      {{ clean_email(primary_field) }},
      {{ clean_email(fallback_field) }}
    )
  {% else %}
    {{ clean_email(primary_field) }}
  {% endif %}
{% endmacro %}