// main.dart
import 'dart:io';
import 'dart:math';

void main() {
  final game = Game();
  game.loadCharacterStats();
  game.loadMonsterStats();
  game.startGame();
}

// 추상 클래스: Entity
abstract class Entity {
  String name;
  int health;
  int attack;
  int defense;

  Entity(this.name, this.health, this.attack, this.defense);

  void showStatus();
}

// 캐릭터 클래스
class Character extends Entity {
  bool isItemUsed = false;

  Character(String name, int health, int attack, int defense)
    : super(name, health, attack, defense);

  void attackMonster(Monster monster) {
    int damage = max(0, attack - monster.defense);
    monster.health -= damage;
    print('$name 이(가) ${monster.name}에게 $damage 데미지를 입혔습니다.');
  }

  void useItem() {
    if (!isItemUsed) {
      isItemUsed = true;
      attack *= 2;
      print('$name 이(가) 아이템을 사용해 공격력이 2배가 되었습니다!');
    } else {
      print('이미 아이템을 사용했습니다.');
    }
  }

  void defend(int monsterAttack) {
    health += monsterAttack;
    print('$name 이(가) 방어하여 체력을 ${monsterAttack}만큼 회복했습니다.');
  }

  @override
  void showStatus() {
    print('[캐릭터] $name - 체력: $health, 공격력: $attack, 방어력: $defense');
  }
}

// 몬스터 클래스
class Monster extends Entity {
  Monster(String name, int health, int maxAttack)
    : super(name, health, Random().nextInt(maxAttack) + 1, 0);

  void attackCharacter(Character character) {
    int damage = max(0, attack - character.defense);
    character.health -= damage;
    print('$name 이(가) ${character.name}에게 $damage 데미지를 입혔습니다.');
  }

  @override
  void showStatus() {
    print('[몬스터] $name - 체력: $health, 공격력: $attack, 방어력: $defense');
  }
}

// 게임 클래스
class Game {
  late Character character;
  List<Monster> monsters = [];
  int defeatedCount = 0;
  int turnCount = 0;

  void loadCharacterStats() {
    try {
      stdout.write('캐릭터 이름을 입력하세요:');
      String? inputName = stdin.readLineSync();
      if (inputName == null ||
          inputName.isEmpty ||
          !RegExp(r'^[a-zA-Z가-힣]+$').hasMatch(inputName)) {
        throw FormatException('이름 형식이 잘못되었습니다.');
      }
      final file = File('characters.txt');
      final stats = file.readAsStringSync().split(',');
      int health = int.parse(stats[0]);
      int attack = int.parse(stats[1]);
      int defense = int.parse(stats[2]);
      character = Character(inputName, health, attack, defense);

      // 보너스 체력
      if (Random().nextInt(100) < 30) {
        character.health += 10;
        print('보너스 체력을 얻었습니다! 현재 체력: ${character.health}');
      }
    } catch (e) {
      print('캐릭터 불러오기 오류: $e');
      exit(1);
    }
  }

  void loadMonsterStats() {
    try {
      final file = File('monsters.txt');
      final lines = file.readAsLinesSync();
      for (var line in lines) {
        final parts = line.split(',');
        monsters.add(
          Monster(parts[0], int.parse(parts[1]), int.parse(parts[2])),
        );
      }
    } catch (e) {
      print('몬스터 불러오기 오류: $e');
      exit(1);
    }
  }

  void startGame() {
    print('\n--- 게임 시작 ---');
    while (character.health > 0 && monsters.isNotEmpty) {
      Monster monster = getRandomMonster();
      print('\n[대결 시작] ${monster.name} 등장!');
      battle(monster);
      if (character.health <= 0) {
        print('\n게임 오버! 패배했습니다.');
        saveResult('패배');
        return;
      }
      stdout.write('다음 몬스터와 대결하시겠습니까? (y/n): ');
      String? next = stdin.readLineSync();
      if (next?.toLowerCase() != 'y') break;
    }
    print('\n축하합니다! 모든 몬스터를 처치했습니다. 승리!');
    saveResult('승리');
  }

  void battle(Monster monster) {
    while (monster.health > 0 && character.health > 0) {
      turnCount++;
      print('\n[턴 $turnCount]');
      character.showStatus();
      monster.showStatus();

      stdout.write('행동 선택 (1:공격, 2:방어, 3:아이템): ');
      String? input = stdin.readLineSync();

      switch (input) {
        case '1':
          character.attackMonster(monster);
          break;
        case '2':
          character.defend(monster.attack);
          break;
        case '3':
          character.useItem();
          break;
        default:
          print('잘못된 입력입니다.');
          continue;
      }

      if (monster.health > 0) {
        monster.attackCharacter(character);
      } else {
        print('${monster.name} 처치 완료!');
        monsters.remove(monster);
        defeatedCount++;
      }

      // 몬스터 방어력 증가
      if (turnCount % 3 == 0) {
        monster.defense += 2;
        print('${monster.name}의 방어력이 증가했습니다! 현재 방어력: ${monster.defense}');
      }
    }
  }

  void saveResult(String result) {
    stdout.write('결과를 저장하시겠습니까? (y/n): ');
    String? input = stdin.readLineSync();
    if (input?.toLowerCase() == 'y') {
      final file = File('result.txt');
      file.writeAsStringSync(
        '이름: ${character.name}, 남은 체력: ${character.health}, 결과: $result',
      );
      print('결과가 result.txt에 저장되었습니다.');
    }
  }

  Monster getRandomMonster() {
    return monsters[Random().nextInt(monsters.length)];
  }
}
