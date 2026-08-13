import 'package:dartz/dartz.dart';
import 'package:petconnect_ai/core/error/exceptions.dart';
import 'package:petconnect_ai/core/error/failure_mapper.dart';
import 'package:petconnect_ai/core/utils/typedefs.dart';
import 'package:petconnect_ai/features/ai_services/data/datasources/ai_remote_datasource.dart';
import 'package:petconnect_ai/features/ai_services/domain/entities/ai_chat_message.dart';
import 'package:petconnect_ai/features/ai_services/domain/entities/ai_conversation.dart';
import 'package:petconnect_ai/features/ai_services/domain/entities/ai_health_scan.dart';
import 'package:petconnect_ai/features/ai_services/domain/repositories/ai_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiRepositoryImpl implements AiRepository {
  const AiRepositoryImpl(this._remote, this._client);

  final AiRemoteDataSource _remote;
  final SupabaseClient _client;

  String get _currentUserId => _client.auth.currentUser?.id ?? '';

  @override
  ResultFuture<List<AiConversation>> getConversations() async {
    try {
      final list = await _remote.getConversations(_currentUserId);
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<AiConversation> createConversation({
    String? petId,
    String title = 'Pet Care Chat',
  }) async {
    try {
      final conversation = await _remote.createConversation(
        userId: _currentUserId,
        petId: petId,
        title: title,
      );
      return Right(conversation);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<AiChatMessage>> getMessages(String conversationId) async {
    try {
      final list = await _remote.getMessages(conversationId);
      return Right(list);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<AiChatMessage> sendChatMessage({
    required String conversationId,
    required String prompt,
    String? petId,
  }) async {
    try {
      final message = await _remote.invokeAiAssistant(
        conversationId: conversationId,
        prompt: prompt,
        petId: petId,
      );
      return Right(message);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<AiHealthScan> analyzeSymptoms({
    String? petId,
    required String symptomDescription,
    String? imageUrl,
  }) async {
    try {
      final scan = await _remote.invokeSymptomScan(
        userId: _currentUserId,
        petId: petId,
        symptomDescription: symptomDescription,
        imageUrl: imageUrl,
      );
      return Right(scan);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<Map<String, dynamic>> generateHealthReport(String petId) async {
    try {
      final report = await _remote.invokeReportGenerator(petId: petId);
      return Right(report);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }

  @override
  ResultFuture<List<AiHealthScan>> getHealthScans() async {
    try {
      final scans = await _remote.getHealthScans(_currentUserId);
      return Right(scans);
    } on AppException catch (e) {
      return Left(FailureMapper.fromException(e));
    } catch (e) {
      return Left(FailureMapper.fromException(ServerException(e.toString())));
    }
  }
}
