import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — a value that is always normalised', () {
    test('trims, lowers and hyphenates', () {
      expect(Slug.of(' Hello  World ').value, 'hello-world');
      expect(Slug.of('Coffee').value, 'coffee');
      expect(Slug.of('one two three').value, 'one-two-three');
    });

    test('and refuses text with nothing in it', () {
      expect(() => Slug.of(''), throwsArgumentError);
      expect(() => Slug.of('   '), throwsArgumentError);
    });
  });

  group('challenge 2 — a check beside a primary constructor', () {
    test('takes the five it should', () {
      expect([1, 2, 3, 4, 5].map((s) => Rating.of(s).stars), [1, 2, 3, 4, 5]);
    });

    test('and refuses the ones on either side', () {
      expect(() => Rating.of(0), throwsArgumentError);
      expect(() => Rating.of(6), throwsArgumentError);
    });
  });

  group('challenge 3 — the door you are already inside', () {
    test('the vault checks what it builds', () {
      expect(() => Vault.rate(0), throwsArgumentError);
      expect(() => Vault.rate(99), throwsArgumentError);
    });

    test('and still builds the ones that are fine', () {
      expect(Vault.rate(3).stars, 3);
    });
  });
}
