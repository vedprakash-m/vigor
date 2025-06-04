"""Add user tiers and usage tracking

Revision ID: 003_add_user_tiers
Revises: cd62a1da2fe2
Create Date: 2025-06-02 10:00:00.000000

"""

import sqlalchemy as sa
from sqlalchemy.dialects import sqlite

from alembic import op

# revision identifiers
revision = "003_add_user_tiers"
down_revision = "002"
branch_labels = None
depends_on = None


def upgrade():
    # Add user tier columns to user_profiles
    with op.batch_alter_table("user_profiles", schema=None) as batch_op:
        batch_op.add_column(
            sa.Column("user_tier", sa.String(), nullable=False, server_default="free")
        )
        batch_op.add_column(sa.Column("tier_updated_at", sa.DateTime(), nullable=True))
        batch_op.add_column(
            sa.Column(
                "monthly_budget", sa.Float(), nullable=False, server_default="5.0"
            )
        )
        batch_op.add_column(
            sa.Column(
                "current_month_usage", sa.Float(), nullable=False, server_default="0.0"
            )
        )

    # Create user_usage_limits table
    op.create_table(
        "user_usage_limits",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.String(), nullable=False),
        sa.Column(
            "daily_requests_used", sa.Integer(), nullable=False, server_default="0"
        ),
        sa.Column(
            "weekly_requests_used", sa.Integer(), nullable=False, server_default="0"
        ),
        sa.Column(
            "monthly_requests_used", sa.Integer(), nullable=False, server_default="0"
        ),
        sa.Column("last_reset_date", sa.Date(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["user_profiles.id"],
        ),
        sa.PrimaryKeyConstraint("id"),
    )

    # Create user_tier_limits table
    op.create_table(
        "user_tier_limits",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("tier_name", sa.String(), nullable=False),
        sa.Column("daily_limit", sa.Integer(), nullable=False),
        sa.Column("weekly_limit", sa.Integer(), nullable=False),
        sa.Column("monthly_limit", sa.Integer(), nullable=False),
        sa.Column("monthly_budget", sa.Float(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("tier_name"),
    )

    # Insert default tier limits
    op.execute(
        """
        INSERT INTO user_tier_limits (tier_name, daily_limit, weekly_limit, monthly_limit, monthly_budget, created_at, updated_at)
        VALUES
            ('free', 10, 50, 200, 5.0, datetime('now'), datetime('now')),
            ('premium', 50, 300, 1000, 25.0, datetime('now'), datetime('now')),
            ('unlimited', 1000, 5000, 20000, 100.0, datetime('now'), datetime('now'))
    """
    )


def downgrade():
    op.drop_table("user_tier_limits")
    op.drop_table("user_usage_limits")

    with op.batch_alter_table("user_profiles", schema=None) as batch_op:
        batch_op.drop_column("current_month_usage")
        batch_op.drop_column("monthly_budget")
        batch_op.drop_column("tier_updated_at")
        batch_op.drop_column("user_tier")
