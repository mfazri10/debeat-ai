from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from collections.abc import Iterable as _Iterable, Mapping as _Mapping
from typing import ClassVar as _ClassVar, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class PersonaContext(_message.Message):
    __slots__ = ("id", "name", "description", "speaking_style", "stance")
    ID_FIELD_NUMBER: _ClassVar[int]
    NAME_FIELD_NUMBER: _ClassVar[int]
    DESCRIPTION_FIELD_NUMBER: _ClassVar[int]
    SPEAKING_STYLE_FIELD_NUMBER: _ClassVar[int]
    STANCE_FIELD_NUMBER: _ClassVar[int]
    id: str
    name: str
    description: str
    speaking_style: str
    stance: str
    def __init__(self, id: _Optional[str] = ..., name: _Optional[str] = ..., description: _Optional[str] = ..., speaking_style: _Optional[str] = ..., stance: _Optional[str] = ...) -> None: ...

class ArgumentHistory(_message.Message):
    __slots__ = ("participant_id", "content", "role", "round_number", "turn_number")
    PARTICIPANT_ID_FIELD_NUMBER: _ClassVar[int]
    CONTENT_FIELD_NUMBER: _ClassVar[int]
    ROLE_FIELD_NUMBER: _ClassVar[int]
    ROUND_NUMBER_FIELD_NUMBER: _ClassVar[int]
    TURN_NUMBER_FIELD_NUMBER: _ClassVar[int]
    participant_id: str
    content: str
    role: str
    round_number: int
    turn_number: int
    def __init__(self, participant_id: _Optional[str] = ..., content: _Optional[str] = ..., role: _Optional[str] = ..., round_number: _Optional[int] = ..., turn_number: _Optional[int] = ...) -> None: ...

class KbChunk(_message.Message):
    __slots__ = ("id", "content", "document_title", "source_url", "similarity")
    ID_FIELD_NUMBER: _ClassVar[int]
    CONTENT_FIELD_NUMBER: _ClassVar[int]
    DOCUMENT_TITLE_FIELD_NUMBER: _ClassVar[int]
    SOURCE_URL_FIELD_NUMBER: _ClassVar[int]
    SIMILARITY_FIELD_NUMBER: _ClassVar[int]
    id: str
    content: str
    document_title: str
    source_url: str
    similarity: float
    def __init__(self, id: _Optional[str] = ..., content: _Optional[str] = ..., document_title: _Optional[str] = ..., source_url: _Optional[str] = ..., similarity: _Optional[float] = ...) -> None: ...

class OpponentRequest(_message.Message):
    __slots__ = ("session_id", "topic", "format", "language", "difficulty", "ai_provider", "persona", "history", "kb_context")
    SESSION_ID_FIELD_NUMBER: _ClassVar[int]
    TOPIC_FIELD_NUMBER: _ClassVar[int]
    FORMAT_FIELD_NUMBER: _ClassVar[int]
    LANGUAGE_FIELD_NUMBER: _ClassVar[int]
    DIFFICULTY_FIELD_NUMBER: _ClassVar[int]
    AI_PROVIDER_FIELD_NUMBER: _ClassVar[int]
    PERSONA_FIELD_NUMBER: _ClassVar[int]
    HISTORY_FIELD_NUMBER: _ClassVar[int]
    KB_CONTEXT_FIELD_NUMBER: _ClassVar[int]
    session_id: str
    topic: str
    format: str
    language: str
    difficulty: str
    ai_provider: str
    persona: PersonaContext
    history: _containers.RepeatedCompositeFieldContainer[ArgumentHistory]
    kb_context: _containers.RepeatedCompositeFieldContainer[KbChunk]
    def __init__(self, session_id: _Optional[str] = ..., topic: _Optional[str] = ..., format: _Optional[str] = ..., language: _Optional[str] = ..., difficulty: _Optional[str] = ..., ai_provider: _Optional[str] = ..., persona: _Optional[_Union[PersonaContext, _Mapping]] = ..., history: _Optional[_Iterable[_Union[ArgumentHistory, _Mapping]]] = ..., kb_context: _Optional[_Iterable[_Union[KbChunk, _Mapping]]] = ...) -> None: ...

class OpponentResponse(_message.Message):
    __slots__ = ("content", "provider_used", "tokens_used", "latency_ms")
    CONTENT_FIELD_NUMBER: _ClassVar[int]
    PROVIDER_USED_FIELD_NUMBER: _ClassVar[int]
    TOKENS_USED_FIELD_NUMBER: _ClassVar[int]
    LATENCY_MS_FIELD_NUMBER: _ClassVar[int]
    content: str
    provider_used: str
    tokens_used: int
    latency_ms: int
    def __init__(self, content: _Optional[str] = ..., provider_used: _Optional[str] = ..., tokens_used: _Optional[int] = ..., latency_ms: _Optional[int] = ...) -> None: ...

class OpponentChunk(_message.Message):
    __slots__ = ("content", "is_done", "provider_used")
    CONTENT_FIELD_NUMBER: _ClassVar[int]
    IS_DONE_FIELD_NUMBER: _ClassVar[int]
    PROVIDER_USED_FIELD_NUMBER: _ClassVar[int]
    content: str
    is_done: bool
    provider_used: str
    def __init__(self, content: _Optional[str] = ..., is_done: _Optional[bool] = ..., provider_used: _Optional[str] = ...) -> None: ...

class ScoreRequest(_message.Message):
    __slots__ = ("session_id", "argument_id", "content", "language", "history", "kb_context")
    SESSION_ID_FIELD_NUMBER: _ClassVar[int]
    ARGUMENT_ID_FIELD_NUMBER: _ClassVar[int]
    CONTENT_FIELD_NUMBER: _ClassVar[int]
    LANGUAGE_FIELD_NUMBER: _ClassVar[int]
    HISTORY_FIELD_NUMBER: _ClassVar[int]
    KB_CONTEXT_FIELD_NUMBER: _ClassVar[int]
    session_id: str
    argument_id: str
    content: str
    language: str
    history: _containers.RepeatedCompositeFieldContainer[ArgumentHistory]
    kb_context: _containers.RepeatedCompositeFieldContainer[KbChunk]
    def __init__(self, session_id: _Optional[str] = ..., argument_id: _Optional[str] = ..., content: _Optional[str] = ..., language: _Optional[str] = ..., history: _Optional[_Iterable[_Union[ArgumentHistory, _Mapping]]] = ..., kb_context: _Optional[_Iterable[_Union[KbChunk, _Mapping]]] = ...) -> None: ...

class ScoreResponse(_message.Message):
    __slots__ = ("logika", "retorika", "dampak")
    LOGIKA_FIELD_NUMBER: _ClassVar[int]
    RETORIKA_FIELD_NUMBER: _ClassVar[int]
    DAMPAK_FIELD_NUMBER: _ClassVar[int]
    logika: JudgeResult
    retorika: JudgeResult
    dampak: JudgeResult
    def __init__(self, logika: _Optional[_Union[JudgeResult, _Mapping]] = ..., retorika: _Optional[_Union[JudgeResult, _Mapping]] = ..., dampak: _Optional[_Union[JudgeResult, _Mapping]] = ...) -> None: ...

class JudgeResult(_message.Message):
    __slots__ = ("judge_type", "argument_strength", "fact_data_usage", "rhetoric_technique", "responsiveness", "clarity_structure", "total_score", "summary", "highlights_positive", "highlights_negative", "fallacy_detected", "suggestion")
    JUDGE_TYPE_FIELD_NUMBER: _ClassVar[int]
    ARGUMENT_STRENGTH_FIELD_NUMBER: _ClassVar[int]
    FACT_DATA_USAGE_FIELD_NUMBER: _ClassVar[int]
    RHETORIC_TECHNIQUE_FIELD_NUMBER: _ClassVar[int]
    RESPONSIVENESS_FIELD_NUMBER: _ClassVar[int]
    CLARITY_STRUCTURE_FIELD_NUMBER: _ClassVar[int]
    TOTAL_SCORE_FIELD_NUMBER: _ClassVar[int]
    SUMMARY_FIELD_NUMBER: _ClassVar[int]
    HIGHLIGHTS_POSITIVE_FIELD_NUMBER: _ClassVar[int]
    HIGHLIGHTS_NEGATIVE_FIELD_NUMBER: _ClassVar[int]
    FALLACY_DETECTED_FIELD_NUMBER: _ClassVar[int]
    SUGGESTION_FIELD_NUMBER: _ClassVar[int]
    judge_type: str
    argument_strength: int
    fact_data_usage: int
    rhetoric_technique: int
    responsiveness: int
    clarity_structure: int
    total_score: float
    summary: str
    highlights_positive: _containers.RepeatedScalarFieldContainer[str]
    highlights_negative: _containers.RepeatedScalarFieldContainer[str]
    fallacy_detected: str
    suggestion: str
    def __init__(self, judge_type: _Optional[str] = ..., argument_strength: _Optional[int] = ..., fact_data_usage: _Optional[int] = ..., rhetoric_technique: _Optional[int] = ..., responsiveness: _Optional[int] = ..., clarity_structure: _Optional[int] = ..., total_score: _Optional[float] = ..., summary: _Optional[str] = ..., highlights_positive: _Optional[_Iterable[str]] = ..., highlights_negative: _Optional[_Iterable[str]] = ..., fallacy_detected: _Optional[str] = ..., suggestion: _Optional[str] = ...) -> None: ...

class AudienceRequest(_message.Message):
    __slots__ = ("avg_judge_score", "language", "topic")
    AVG_JUDGE_SCORE_FIELD_NUMBER: _ClassVar[int]
    LANGUAGE_FIELD_NUMBER: _ClassVar[int]
    TOPIC_FIELD_NUMBER: _ClassVar[int]
    avg_judge_score: float
    language: str
    topic: str
    def __init__(self, avg_judge_score: _Optional[float] = ..., language: _Optional[str] = ..., topic: _Optional[str] = ...) -> None: ...

class AudienceResponse(_message.Message):
    __slots__ = ("reaction_type", "intensity", "comments")
    REACTION_TYPE_FIELD_NUMBER: _ClassVar[int]
    INTENSITY_FIELD_NUMBER: _ClassVar[int]
    COMMENTS_FIELD_NUMBER: _ClassVar[int]
    reaction_type: str
    intensity: int
    comments: _containers.RepeatedScalarFieldContainer[str]
    def __init__(self, reaction_type: _Optional[str] = ..., intensity: _Optional[int] = ..., comments: _Optional[_Iterable[str]] = ...) -> None: ...

class DebateEvent(_message.Message):
    __slots__ = ("argument_submitted", "session_started", "session_ended")
    ARGUMENT_SUBMITTED_FIELD_NUMBER: _ClassVar[int]
    SESSION_STARTED_FIELD_NUMBER: _ClassVar[int]
    SESSION_ENDED_FIELD_NUMBER: _ClassVar[int]
    argument_submitted: ArgumentSubmittedEvent
    session_started: SessionStartedEvent
    session_ended: SessionEndedEvent
    def __init__(self, argument_submitted: _Optional[_Union[ArgumentSubmittedEvent, _Mapping]] = ..., session_started: _Optional[_Union[SessionStartedEvent, _Mapping]] = ..., session_ended: _Optional[_Union[SessionEndedEvent, _Mapping]] = ...) -> None: ...

class ArgumentSubmittedEvent(_message.Message):
    __slots__ = ("session_id", "argument_id", "content", "participant_id", "round_number", "turn_number")
    SESSION_ID_FIELD_NUMBER: _ClassVar[int]
    ARGUMENT_ID_FIELD_NUMBER: _ClassVar[int]
    CONTENT_FIELD_NUMBER: _ClassVar[int]
    PARTICIPANT_ID_FIELD_NUMBER: _ClassVar[int]
    ROUND_NUMBER_FIELD_NUMBER: _ClassVar[int]
    TURN_NUMBER_FIELD_NUMBER: _ClassVar[int]
    session_id: str
    argument_id: str
    content: str
    participant_id: str
    round_number: int
    turn_number: int
    def __init__(self, session_id: _Optional[str] = ..., argument_id: _Optional[str] = ..., content: _Optional[str] = ..., participant_id: _Optional[str] = ..., round_number: _Optional[int] = ..., turn_number: _Optional[int] = ...) -> None: ...

class SessionStartedEvent(_message.Message):
    __slots__ = ("session_id", "topic", "format", "language", "difficulty", "ai_provider", "ai_persona")
    SESSION_ID_FIELD_NUMBER: _ClassVar[int]
    TOPIC_FIELD_NUMBER: _ClassVar[int]
    FORMAT_FIELD_NUMBER: _ClassVar[int]
    LANGUAGE_FIELD_NUMBER: _ClassVar[int]
    DIFFICULTY_FIELD_NUMBER: _ClassVar[int]
    AI_PROVIDER_FIELD_NUMBER: _ClassVar[int]
    AI_PERSONA_FIELD_NUMBER: _ClassVar[int]
    session_id: str
    topic: str
    format: str
    language: str
    difficulty: str
    ai_provider: str
    ai_persona: PersonaContext
    def __init__(self, session_id: _Optional[str] = ..., topic: _Optional[str] = ..., format: _Optional[str] = ..., language: _Optional[str] = ..., difficulty: _Optional[str] = ..., ai_provider: _Optional[str] = ..., ai_persona: _Optional[_Union[PersonaContext, _Mapping]] = ...) -> None: ...

class SessionEndedEvent(_message.Message):
    __slots__ = ("session_id",)
    SESSION_ID_FIELD_NUMBER: _ClassVar[int]
    session_id: str
    def __init__(self, session_id: _Optional[str] = ...) -> None: ...

class DebateUpdate(_message.Message):
    __slots__ = ("opponent_chunk", "judge_result", "audience_react", "error")
    OPPONENT_CHUNK_FIELD_NUMBER: _ClassVar[int]
    JUDGE_RESULT_FIELD_NUMBER: _ClassVar[int]
    AUDIENCE_REACT_FIELD_NUMBER: _ClassVar[int]
    ERROR_FIELD_NUMBER: _ClassVar[int]
    opponent_chunk: OpponentChunk
    judge_result: JudgeResult
    audience_react: AudienceResponse
    error: ErrorUpdate
    def __init__(self, opponent_chunk: _Optional[_Union[OpponentChunk, _Mapping]] = ..., judge_result: _Optional[_Union[JudgeResult, _Mapping]] = ..., audience_react: _Optional[_Union[AudienceResponse, _Mapping]] = ..., error: _Optional[_Union[ErrorUpdate, _Mapping]] = ...) -> None: ...

class ErrorUpdate(_message.Message):
    __slots__ = ("code", "message", "retryable")
    CODE_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    RETRYABLE_FIELD_NUMBER: _ClassVar[int]
    code: str
    message: str
    retryable: bool
    def __init__(self, code: _Optional[str] = ..., message: _Optional[str] = ..., retryable: _Optional[bool] = ...) -> None: ...

class SearchRequest(_message.Message):
    __slots__ = ("embedding", "top_k", "threshold", "language", "topic_tags")
    EMBEDDING_FIELD_NUMBER: _ClassVar[int]
    TOP_K_FIELD_NUMBER: _ClassVar[int]
    THRESHOLD_FIELD_NUMBER: _ClassVar[int]
    LANGUAGE_FIELD_NUMBER: _ClassVar[int]
    TOPIC_TAGS_FIELD_NUMBER: _ClassVar[int]
    embedding: _containers.RepeatedScalarFieldContainer[float]
    top_k: int
    threshold: float
    language: str
    topic_tags: _containers.RepeatedScalarFieldContainer[str]
    def __init__(self, embedding: _Optional[_Iterable[float]] = ..., top_k: _Optional[int] = ..., threshold: _Optional[float] = ..., language: _Optional[str] = ..., topic_tags: _Optional[_Iterable[str]] = ...) -> None: ...

class SearchResponse(_message.Message):
    __slots__ = ("chunks",)
    CHUNKS_FIELD_NUMBER: _ClassVar[int]
    chunks: _containers.RepeatedCompositeFieldContainer[KbChunk]
    def __init__(self, chunks: _Optional[_Iterable[_Union[KbChunk, _Mapping]]] = ...) -> None: ...

class EmbeddingRequest(_message.Message):
    __slots__ = ("text", "language", "model")
    TEXT_FIELD_NUMBER: _ClassVar[int]
    LANGUAGE_FIELD_NUMBER: _ClassVar[int]
    MODEL_FIELD_NUMBER: _ClassVar[int]
    text: str
    language: str
    model: str
    def __init__(self, text: _Optional[str] = ..., language: _Optional[str] = ..., model: _Optional[str] = ...) -> None: ...

class EmbeddingResponse(_message.Message):
    __slots__ = ("embedding", "model_used", "latency_ms")
    EMBEDDING_FIELD_NUMBER: _ClassVar[int]
    MODEL_USED_FIELD_NUMBER: _ClassVar[int]
    LATENCY_MS_FIELD_NUMBER: _ClassVar[int]
    embedding: _containers.RepeatedScalarFieldContainer[float]
    model_used: str
    latency_ms: int
    def __init__(self, embedding: _Optional[_Iterable[float]] = ..., model_used: _Optional[str] = ..., latency_ms: _Optional[int] = ...) -> None: ...

class IngestRequest(_message.Message):
    __slots__ = ("source_type", "source_url", "title", "language", "topic_tags", "persona_tags", "file_content", "ingested_by_id")
    SOURCE_TYPE_FIELD_NUMBER: _ClassVar[int]
    SOURCE_URL_FIELD_NUMBER: _ClassVar[int]
    TITLE_FIELD_NUMBER: _ClassVar[int]
    LANGUAGE_FIELD_NUMBER: _ClassVar[int]
    TOPIC_TAGS_FIELD_NUMBER: _ClassVar[int]
    PERSONA_TAGS_FIELD_NUMBER: _ClassVar[int]
    FILE_CONTENT_FIELD_NUMBER: _ClassVar[int]
    INGESTED_BY_ID_FIELD_NUMBER: _ClassVar[int]
    source_type: str
    source_url: str
    title: str
    language: str
    topic_tags: _containers.RepeatedScalarFieldContainer[str]
    persona_tags: _containers.RepeatedScalarFieldContainer[str]
    file_content: bytes
    ingested_by_id: str
    def __init__(self, source_type: _Optional[str] = ..., source_url: _Optional[str] = ..., title: _Optional[str] = ..., language: _Optional[str] = ..., topic_tags: _Optional[_Iterable[str]] = ..., persona_tags: _Optional[_Iterable[str]] = ..., file_content: _Optional[bytes] = ..., ingested_by_id: _Optional[str] = ...) -> None: ...

class IngestProgress(_message.Message):
    __slots__ = ("status", "chunks_processed", "total_chunks", "current_step", "error_message")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    CHUNKS_PROCESSED_FIELD_NUMBER: _ClassVar[int]
    TOTAL_CHUNKS_FIELD_NUMBER: _ClassVar[int]
    CURRENT_STEP_FIELD_NUMBER: _ClassVar[int]
    ERROR_MESSAGE_FIELD_NUMBER: _ClassVar[int]
    status: str
    chunks_processed: int
    total_chunks: int
    current_step: str
    error_message: str
    def __init__(self, status: _Optional[str] = ..., chunks_processed: _Optional[int] = ..., total_chunks: _Optional[int] = ..., current_step: _Optional[str] = ..., error_message: _Optional[str] = ...) -> None: ...
