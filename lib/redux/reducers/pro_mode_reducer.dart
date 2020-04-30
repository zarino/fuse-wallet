import 'package:peepl/models/pro/pro_wallet_state.dart';
import 'package:peepl/models/pro/token.dart';
import 'package:peepl/redux/actions/pro_mode_wallet_actions.dart';
import 'package:peepl/redux/actions/user_actions.dart';
import 'package:redux/redux.dart';

final proWalletReducers = combineReducers<ProWalletState>([
  TypedReducer<ProWalletState, StartListenToTransferEventsSuccess>(_startListenToTransferEventsSuccess),
  TypedReducer<ProWalletState, UpdateToken>(_updateToken),
  TypedReducer<ProWalletState, AddToken>(_addToken),
  TypedReducer<ProWalletState, UpadteBlockNumber>(_updateBlockNumber),
  TypedReducer<ProWalletState, InitWeb3ProModeSuccess>(_initWeb3ProModeSuccess),
  TypedReducer<ProWalletState, CreateLocalAccountSuccess>(_createNewWalletSuccess),
]);

ProWalletState _createNewWalletSuccess(ProWalletState state, CreateLocalAccountSuccess action) {
  return ProWalletState.initial();
}

ProWalletState _initWeb3ProModeSuccess(ProWalletState state, InitWeb3ProModeSuccess action) {
  return state.copyWith(web3: action.web3);
}

ProWalletState _updateBlockNumber(ProWalletState state, UpadteBlockNumber action) {
  return state.copyWith(blockNumber: action.blockNumber);
}

ProWalletState _startListenToTransferEventsSuccess(ProWalletState state, StartListenToTransferEventsSuccess action) {
  return state.copyWith(isListenToTransferEvents: true);
}

ProWalletState _addToken(ProWalletState state, AddToken action) {
  List<Token> tokens = state.tokens;
  bool isTokenExist = tokens.any((token) => token.address == action.token.address);
  if (isTokenExist) {
    List<Token> tokens = state.tokens;
    int index = tokens.indexWhere((token) => token.address == action.token.address);
    tokens[index] = action.token;
    return state.copyWith(tokens: tokens);
  }
  return state.copyWith(tokens: tokens..add(action.token));
}

ProWalletState _updateToken(ProWalletState state, UpdateToken action) {
  List<Token> tokens = state.tokens;
  int index = tokens.indexOf(action.token);
  tokens[index] = action.tokenToUpdate;
  return state.copyWith(tokens: tokens);
}
