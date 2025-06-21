"""merge_migrations

Revision ID: 017888ba4759
Revises: 003_add_user_tiers, cd62a1da2fe2
Create Date: 2025-06-21 09:53:03.160297

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '017888ba4759'
down_revision = ('003_add_user_tiers', 'cd62a1da2fe2')
branch_labels = None
depends_on = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
