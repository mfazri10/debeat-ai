import asyncio
import grpc
import logging
from concurrent import futures

# Generated gRPC code (setelah `python -m grpc_tools.protoc ...`)
import sys
sys.path.insert(0, "gen/python")

from debateai.v1 import debate_pb2_grpc
from debateai.v1 import knowledge_pb2_grpc

from app.servicers.debate_servicer import DebateEngineServicer
from app.servicers.knowledge_servicer import KnowledgeBaseServicer
from app.core.config import settings

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


async def serve():
    """Menjalankan gRPC server untuk Debate Engine."""
    server = grpc.aio.server(
        futures.ThreadPoolExecutor(max_workers=20),
        options=[
            # Ukuran pesan maksimum (50MB untuk PDF ingestion)
            ("grpc.max_receive_message_length", 50 * 1024 * 1024),
            ("grpc.max_send_message_length", 50 * 1024 * 1024),
            # Keepalive — jaga koneksi tetap hidup dengan Go API Gateway
            ("grpc.keepalive_time_ms", 10_000),
            ("grpc.keepalive_timeout_ms", 5_000),
            ("grpc.keepalive_permit_without_calls", True),
        ],
    )

    # Register servicers
    debate_pb2_grpc.add_DebateEngineServicer_to_server(
        DebateEngineServicer(), server
    )
    knowledge_pb2_grpc.add_KnowledgeBaseServicer_to_server(
        KnowledgeBaseServicer(), server
    )

    # Bind ke port
    listen_addr = f"[::]:{settings.GRPC_PORT}"
    server.add_insecure_port(listen_addr)  # TODO: TLS di production

    await server.start()
    logger.info(f"🐍 Debate Engine gRPC server started on {listen_addr}")

    # Graceful shutdown
    async def shutdown():
        logger.info("Shutting down gRPC server...")
        await server.stop(grace=5)

    try:
        await server.wait_for_termination()
    except KeyboardInterrupt:
        await shutdown()


if __name__ == "__main__":
    asyncio.run(serve())
