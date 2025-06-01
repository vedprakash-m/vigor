"""Add admin tables for AI provider management and budget tracking

Revision ID: 002
Revises: 
Create Date: 2024-12-19 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import sqlite

# revision identifiers
revision = '002'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    # AI Provider Priorities table
    op.create_table('ai_provider_priorities',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('provider_name', sa.String(), nullable=False),
        sa.Column('model_name', sa.String(), nullable=False),
        sa.Column('priority', sa.Integer(), nullable=False),
        sa.Column('is_enabled', sa.Boolean(), nullable=False, default=True),
        sa.Column('max_daily_cost', sa.Float(), nullable=True),
        sa.Column('max_weekly_cost', sa.Float(), nullable=True),
        sa.Column('max_monthly_cost', sa.Float(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Create indexes for efficient queries
    op.create_index('idx_provider_priority', 'ai_provider_priorities', ['priority', 'is_enabled'])
    op.create_index('idx_provider_name', 'ai_provider_priorities', ['provider_name'])

    # Budget Settings table
    op.create_table('budget_settings',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('total_weekly_budget', sa.Float(), nullable=False),
        sa.Column('total_monthly_budget', sa.Float(), nullable=False),
        sa.Column('alert_threshold_percentage', sa.Float(), nullable=False, default=80.0),
        sa.Column('auto_disable_on_budget_exceeded', sa.Boolean(), nullable=False, default=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )

    # AI Usage Logs table
    op.create_table('ai_usage_logs',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('provider_name', sa.String(), nullable=False),
        sa.Column('model_name', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=True),
        sa.Column('endpoint', sa.String(), nullable=False),
        sa.Column('input_tokens', sa.Integer(), nullable=False),
        sa.Column('output_tokens', sa.Integer(), nullable=False),
        sa.Column('cost', sa.Float(), nullable=False),
        sa.Column('response_time_ms', sa.Integer(), nullable=False),
        sa.Column('success', sa.Boolean(), nullable=False),
        sa.Column('error_message', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Create indexes for analytics queries
    op.create_index('idx_usage_date_provider', 'ai_usage_logs', ['created_at', 'provider_name'])
    op.create_index('idx_usage_cost_tracking', 'ai_usage_logs', ['created_at', 'cost', 'provider_name'])
    op.create_index('idx_usage_success', 'ai_usage_logs', ['success'])
    op.create_index('idx_usage_user', 'ai_usage_logs', ['user_id'])

    # Admin Settings table
    op.create_table('admin_settings',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('key', sa.String(), nullable=False),
        sa.Column('value', sa.Text(), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    
    op.create_index('idx_admin_key', 'admin_settings', ['key'], unique=True)

    # Insert default provider priorities (if no LLM providers are configured)
    op.execute("""
        INSERT INTO ai_provider_priorities (id, provider_name, model_name, priority, is_enabled, created_at, updated_at)
        VALUES 
            ('default-gemini', 'gemini', 'gemini-2.5-flash', 1, 1, datetime('now'), datetime('now')),
            ('default-perplexity', 'perplexity', 'llama-3.1-sonar-small-128k-online', 2, 1, datetime('now'), datetime('now')),
            ('default-openai-4o-mini', 'openai', 'gpt-4o-mini', 3, 1, datetime('now'), datetime('now')),
            ('default-openai-4o', 'openai', 'gpt-4o', 4, 0, datetime('now'), datetime('now')),
            ('default-openai-3.5', 'openai', 'gpt-3.5-turbo', 5, 0, datetime('now'), datetime('now'))
    """)

    # Insert default budget settings ($10/week, $30/month)
    op.execute("""
        INSERT INTO budget_settings (id, total_weekly_budget, total_monthly_budget, alert_threshold_percentage, auto_disable_on_budget_exceeded, created_at, updated_at)
        VALUES ('default-budget', 10.0, 30.0, 80.0, 1, datetime('now'), datetime('now'))
    """)

def downgrade():
    op.drop_table('admin_settings')
    op.drop_table('ai_usage_logs')
    op.drop_table('budget_settings')
    op.drop_table('ai_provider_priorities') 