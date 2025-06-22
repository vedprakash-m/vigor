"""add_missing_user_columns

Revision ID: c5f32a9e5996
Revises: 017888ba4759
Create Date: 2025-01-20 21:01:16.463892

"""
import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision = 'c5f32a9e5996'
down_revision = '017888ba4759'
branch_labels = None
depends_on = None


def upgrade():
    # Add missing columns to user_profiles table
    with op.batch_alter_table('user_profiles', schema=None) as batch_op:
        batch_op.add_column(sa.Column('is_active', sa.Boolean(), nullable=False, server_default='1'))
        batch_op.add_column(sa.Column('hashed_password', sa.String(), nullable=True))
        batch_op.add_column(sa.Column('last_login', sa.DateTime(), nullable=True))


def downgrade():
    # Remove the added columns
    with op.batch_alter_table('user_profiles', schema=None) as batch_op:
        batch_op.drop_column('last_login')
        batch_op.drop_column('hashed_password')
        batch_op.drop_column('is_active')
