"""
Usage Logger
Comprehensive logging system for LLM usage analytics and billing
"""
import logging
from datetime import datetime
from typing import Dict, List, Optional, Any
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class UsageRecord:
    """Individual usage record"""
    request_id: str
    user_id: str
    model_used: str
    provider: str
    tokens_used: int
    cost_estimate: float
    latency_ms: int
    cached: bool
    task_type: Optional[str]
    session_id: Optional[str]
    timestamp: datetime
    success: bool = True
    error_message: Optional[str] = None


class UsageLogger:
    """
    Usage logging system for analytics and billing
    """
    
    def __init__(self, db_session=None):
        self.db = db_session
        self._buffer = []
        self._buffer_size = 100
    
    async def log_request(
        self,
        request_id: str,
        user_id: str,
        model_used: str,
        provider: str,
        tokens_used: int,
        cost_estimate: float,
        latency_ms: int,
        cached: bool = False,
        task_type: Optional[str] = None,
        session_id: Optional[str] = None,
        success: bool = True,
        error_message: Optional[str] = None
    ):
        """Log a usage record"""
        try:
            record = UsageRecord(
                request_id=request_id,
                user_id=user_id,
                model_used=model_used,
                provider=provider,
                tokens_used=tokens_used,
                cost_estimate=cost_estimate,
                latency_ms=latency_ms,
                cached=cached,
                task_type=task_type,
                session_id=session_id,
                timestamp=datetime.utcnow(),
                success=success,
                error_message=error_message
            )
            
            self._buffer.append(record)
            
            # Flush buffer if full
            if len(self._buffer) >= self._buffer_size:
                await self._flush_buffer()
                
        except Exception as e:
            logger.error(f"Failed to log usage record: {e}")
    
    async def _flush_buffer(self):
        """Flush buffered records to database"""
        try:
            if not self._buffer:
                return
            
            # Implementation would batch insert to database
            logger.debug(f"Flushing {len(self._buffer)} usage records")
            self._buffer.clear()
            
        except Exception as e:
            logger.error(f"Failed to flush usage buffer: {e}")
    
    async def shutdown(self):
        """Shutdown and flush remaining records"""
        await self._flush_buffer() 