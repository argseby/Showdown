import 'package:flutter_test/flutter_test.dart';
import 'package:showdown/core/admin_api.dart';
import 'package:showdown/features/admin/settings_form_model.dart';

void main() {
  test('defaults validate and produce an empty patch', () {
    final f = SettingsFormState.fromSettings(AdminSettings.defaults);
    expect(f.validate(), isEmpty);
    expect(f.toPatch(), isEmpty);
    expect(f.hasChanges, isFalse);
    final all = f.toPatch(all: true);
    expect(all.length, 23);
    expect(all['big_blind'], 100);
    expect(all.containsKey('password'), isFalse);
  });

  test('only changed fields go into the patch', () {
    var f = SettingsFormState.fromSettings(AdminSettings.defaults);
    f = f
        .setNumber('big_blind', '200')
        .setNumber('small_blind', '100')
        .setFlag('allow_rebuy', false);
    f = f.copyWith(joinPolicy: 'closed', password: 'secret');
    expect(f.toPatch(), {
      'small_blind': 100,
      'big_blind': 200,
      'join_policy': 'closed',
      'allow_rebuy': false,
      'password': 'secret',
    });
    expect(f.copyWith(clearPassword: true).toPatch()['password'], '');
  });

  test('validation mirrors the server rules', () {
    var f = SettingsFormState.fromSettings(AdminSettings.defaults);
    expect(
      f.setNumber('max_players', '1').validate()['max_players'],
      SettingsError.maxPlayers,
    );
    expect(
      f.setNumber('max_players', '11').validate()['max_players'],
      SettingsError.maxPlayers,
    );
    expect(
      f.setNumber('max_players', '3').validate(seated: 4)['max_players'],
      SettingsError.maxPlayers,
    );
    expect(
      f.setNumber('max_players', 'x').validate()['max_players'],
      SettingsError.integer,
    );
    expect(
      f.setNumber('start_money', '0').validate()['start_money'],
      SettingsError.startMoney,
    );
    expect(
      f.setNumber('small_blind', '0').validate()['small_blind'],
      SettingsError.smallBlind,
    );
    expect(
      f.setNumber('big_blind', '10').validate()['big_blind'],
      SettingsError.bigBlind,
    );
    expect(f.setNumber('ante', '-1').validate()['ante'], SettingsError.ante);
    expect(
      f.setNumber('turn_time', '4').validate()['turn_time'],
      SettingsError.turnTime,
    );
    expect(
      f
          .setNumber('disconnected_turn_time', '31')
          .validate()['disconnected_turn_time'],
      SettingsError.disconnected,
    );
    expect(
      f
          .setNumber('sit_out_after_missed_turns', '0')
          .validate()['sit_out_after_missed_turns'],
      SettingsError.sitOut,
    );
    expect(
      f.setNumber('hand_delay_ms', '100').validate()['hand_delay_ms'],
      SettingsError.handDelay,
    );
    expect(
      f.copyWith(password: 'abc').validate()['password'],
      SettingsError.password,
    );
    expect(f.copyWith(password: 'abcd').validate(), isEmpty);
    expect(f.validate(requireName: true)['name'], SettingsError.name);
    expect(f.copyWith(name: 'Friday').validate(requireName: true), isEmpty);
    f = f
        .setNumber('turn_time', '60')
        .setNumber('disconnected_turn_time', '45');
    expect(f.validate(), isEmpty);
  });

  test('applies-when table covers every field', () {
    for (final f in AdminSettings.defaults.toFields().keys) {
      expect(settingsApplies.containsKey(f), isTrue, reason: f);
    }
    expect(settingsApplies['big_blind'], AppliesWhen.nextHand);
    expect(settingsApplies['max_players'], AppliesWhen.immediately);
  });
}
