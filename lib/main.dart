/*
 * Copyright 2019 Kiyohito Nara
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Trending',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: _RepositoriesPage(),
    );
  }
}

class _RepositoriesPage extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Repositories'),
        ),
        body: _buildList());
  }

  Widget _buildList() {
    return FutureBuilder(
      future: _fetchRepositories(),
      builder: (BuildContext context, AsyncSnapshot<List<Repository>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator());
        }

        List<Repository> repositories = snapshot.data;

        return ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(repositories[index].avatar),
              ),
              title: Text(
                repositories[index].name,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
              subtitle: Text(
                repositories[index].description,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
              onTap: () {
                if (kIsWeb) {
                  _scaffoldKey.currentState.showSnackBar(
                    SnackBar(
                      content: Text('Currently not supported.'),
                    ),
                  );

                  return;
                }

                launch(repositories[index].url);
              },
            );
          },
          itemCount: repositories.length,
        );
      },
    );
  }

  Future<List<Repository>> _fetchRepositories({String language = 'dart', String since = 'weekly'}) async {
    Map<String, String> parameters = {'language': language, 'since': since};
    final url = Uri.https('github-trending-api.now.sh', 'repositories', parameters);
    final response = await http.get(url);
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();

    return parsed.map<Repository>((json) => Repository.fromJson(json)).toList();
  }
}

class Repository {
  final String author;
  final String name;
  final String avatar;
  final String url;
  final String description;
  final String language;
  final String languageColor;
  final int stars;
  final int forks;

  Repository(
      {this.author,
      this.name,
      this.avatar,
      this.url,
      this.description,
      this.language,
      this.languageColor,
      this.stars,
      this.forks});

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
        author: json['author'],
        name: json['name'],
        avatar: json['avatar'],
        url: json['url'],
        description: json['description'],
        language: json['language'],
        languageColor: json['languageColor'],
        stars: json['stars'],
        forks: json['forks']);
  }
}
