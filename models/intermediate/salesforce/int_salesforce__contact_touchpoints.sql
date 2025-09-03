{{ config(materialized='view') }}

with contact_campaign_members as (
    select *
    from {{ ref('stg_salesforce__campaign_members') }}
    where member_type = 'Contact'
        and contact_id is not null
),

campaigns as (
    select 
        id as campaign_id,
        name as campaign_name,
        type as campaign_type
    from {{ ref('stg_salesforce__campaigns') }}
),

contacts as (
    select 
        id as contact_id
    from {{ ref('stg_salesforce__contacts') }}
),

contact_touchpoints as (
    select
        cm.contact_id,
        cm.campaign_id,
        c.campaign_name,
        c.campaign_type,
        cm.has_responded,
        cm.first_responded_date,
        cm.created_at as touchpoint_date,
        
        row_number() over (
            partition by cm.contact_id 
            order by cm.created_at
        ) as touchpoint_sequence,
        
        count(*) over (
            partition by cm.contact_id
        ) as total_touchpoints,
        
        coalesce(
            date_diff(
                cm.created_at,
                lag(cm.created_at) over (
                    partition by cm.contact_id 
                    order by cm.created_at
                ),
                day
            ),
            0
        ) as days_since_last_touch
        
    from contact_campaign_members cm
    inner join campaigns c
        on cm.campaign_id = c.campaign_id
    inner join contacts ct
        on cm.contact_id = ct.contact_id
)

select * from contact_touchpoints