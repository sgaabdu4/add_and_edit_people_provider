// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

@immutable
class Person {
  final String name;
  final int age;
  final String uuid;
  Person({
    required this.name,
    required this.age,
    String? uuid,
  }) : uuid = uuid ??
            const Uuid()
                .v4(); //don't need to provide uuid. Already is provided.

// This method returns a new Person object with updated properties.
//It takes optional parameters name and age and creates a new Person object with the same uuid as the original object.
//If the name or age is not provided, the existing values are used instead.
  Person updated([String? name, int? age]) =>
      Person(name: name ?? this.name, age: age ?? this.age, uuid: uuid);

  String get displayName => '$name ($age year old)';

  // operator == Override: This method overrides the == operator to compare two Person objects.
  //It compares the uuid property of both objects to determine equality.
  @override
  bool operator ==(covariant Person other) => uuid == other.uuid;

  //hashCode Override: This method overrides the hashCode getter to generate a hash code based on the uuid property.
  //The hashCode is used in data structures like Set and Map to efficiently organize and retrieve objects.
  @override
  int get hashCode => uuid.hashCode;
  // In Dart, it is recommended that whenever you override the operator == method to compare objects for equality,
  //you should also override the hashCode method.

  //overriding the toString parameter for the object so it gives the value of what's inside rather then <Object of instance Person>
  @override
  String toString() => 'Person(name: $name, age: $age, uuid: $uuid)';
}

class DataModel extends ChangeNotifier {
  //
  final List<Person> _people = [];
  //read the count of the private list instead of making the list public
  int get count => _people.length;

  //exposes the list of people but not able to change them - immutable list
  UnmodifiableListView<Person> get people => UnmodifiableListView(_people);

  void addPerson(Person person) {
    _people.add(person);
    notifyListeners();
  }

  void removePerson(Person person) {
    _people.remove(person);
    notifyListeners();
  }

  void update(Person updatedPerson) {
    //finding index of the perosn using the uuid
    final index = _people.indexOf(updatedPerson);

    //find the person in the array of people
    final existingPerson = _people[index];

    //if the old person name or age is different then updated it of the exisiting person and add to the list
    if (existingPerson.name != updatedPerson.name ||
        existingPerson.age != updatedPerson.age) {
      _people[index] = existingPerson.updated(
        updatedPerson.name,
        updatedPerson.age,
      );
      notifyListeners();
    }
  }
}

final peopleProvider = ChangeNotifierProvider((_) => DataModel());

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Users'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final dataModel = ref.watch(peopleProvider);
          return ListView.builder(
            itemCount: dataModel.count,
            itemBuilder: (BuildContext context, int index) {
              final person = dataModel.people[index];
              return ListTile(
                title: GestureDetector(
                  onTap: () async {
                    final updatedPerson =
                        await createOrUpdatePersonDialog(context, person);
                    if (updatedPerson != null) {
                      dataModel.update(updatedPerson);
                    }
                  },
                  child: Text(person.displayName),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final person = await createOrUpdatePersonDialog(context);
          if (person != null) {
            final dataModel = ref.read(peopleProvider);
            dataModel.addPerson(person);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

final nameController = TextEditingController();
final ageController = TextEditingController();

Future<Person?> createOrUpdatePersonDialog(
  BuildContext context, [
  Person? existingPerson,
]) {
  String? name = existingPerson?.name;
  int? age = existingPerson?.age;

  nameController.text = name ?? '';
  ageController.text = age?.toString() ?? '';

  return showDialog<Person?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create a Person'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: 'Enter Name Here...'),
              onChanged: (value) => name = value,
            ),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(labelText: 'Enter Age Here...'),
              onChanged: (value) => age = int.tryParse(value),
            )
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  if (name != null && age != null) {
                    if (existingPerson != null) {
                      //if there is an existing person, then update that person.
                      final newPerson = existingPerson.updated(name, age);
                      Navigator.of(context).pop(newPerson);
                    } else {
                      //no existing person create a new one
                      final newPerson = Person(name: name!, age: age!);
                      Navigator.of(context).pop(newPerson);
                    }
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Create'))
          ],
        );
      });
}
