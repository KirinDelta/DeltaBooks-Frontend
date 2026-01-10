import 'package:flutter/foundation.dart';
import '../models/invitation.dart';
import '../services/api_service.dart';
import 'dart:convert';

class InvitationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Invitation> _sentInvitations = [];
  List<Invitation> _receivedInvitations = [];
  bool _isLoading = false;

  List<Invitation> get sentInvitations => _sentInvitations;
  List<Invitation> get receivedInvitations => _receivedInvitations;
  bool get isLoading => _isLoading;
  
  int get pendingReceivedCount => 
      _receivedInvitations.where((inv) => inv.isPending).length;

  Future<void> fetchInvitations() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Fetch sent invitations
      final sentResponse = await _apiService.get('/api/v1/invitations?type=sent');
      if (sentResponse.statusCode == 200) {
        final List<dynamic> sentData = jsonDecode(sentResponse.body);
        _sentInvitations = sentData.map((json) => Invitation.fromJson(json)).toList();
      }

      // Fetch received invitations
      final receivedResponse = await _apiService.get('/api/v1/invitations?type=received');
      if (receivedResponse.statusCode == 200) {
        final List<dynamic> receivedData = jsonDecode(receivedResponse.body);
        _receivedInvitations = receivedData.map((json) => Invitation.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching invitations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    try {
      final response = await _apiService.get('/api/v1/users/search?email=$email');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error searching user: $e');
    }
    return null;
  }

  Future<bool> sendInvitation(int receiverId, int libraryId) async {
    try {
      final response = await _apiService.post('/api/v1/invitations', {
        'invitation': {
          'receiver_id': receiverId,
          'library_id': libraryId,
        }
      });
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchInvitations();
        return true;
      }
    } catch (e) {
      debugPrint('Error sending invitation: $e');
    }
    return false;
  }

  Future<bool> acceptInvitation(int invitationId) async {
    try {
      final response = await _apiService.put('/api/v1/invitations/$invitationId/accept', {});
      
      if (response.statusCode == 200) {
        await fetchInvitations();
        return true;
      }
    } catch (e) {
      debugPrint('Error accepting invitation: $e');
    }
    return false;
  }

  Future<bool> rejectInvitation(int invitationId) async {
    try {
      final response = await _apiService.put('/api/v1/invitations/$invitationId/reject', {});
      
      if (response.statusCode == 200) {
        await fetchInvitations();
        return true;
      }
    } catch (e) {
      debugPrint('Error rejecting invitation: $e');
    }
    return false;
  }

  Future<bool> cancelInvitation(int invitationId) async {
    try {
      final response = await _apiService.delete('/api/v1/invitations/$invitationId');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchInvitations();
        return true;
      }
    } catch (e) {
      debugPrint('Error canceling invitation: $e');
    }
    return false;
  }
}
