import 'dart:convert';

import 'package:fluffy_board/dashboard/filemanager/add_folder.dart';
import 'package:fluffy_board/dashboard/filemanager/add_offline_whiteboard.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'filemanager/add_ext_whiteboard.dart';
import 'filemanager/add_whiteboard.dart';
import 'filemanager/file_manager_types.dart';

class ActionButtons extends StatefulWidget {
  final String authToken, parent;
  final RefreshController _refreshController;
  final OfflineWhiteboards offlineWhiteboards;
  final Set<String> offlineWhiteboardIds;
  final bool online;
  final Directories directories;

  ActionButtons(
      this.authToken,
      this.parent,
      this._refreshController,
      this.offlineWhiteboards,
      this.offlineWhiteboardIds,
      this.online,
      this.directories);

  @override
  _ActionButtonsState createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<ActionButtons> {
  final LocalStorage fileManagerStorage = new LocalStorage('filemanager');
  final LocalStorage fileManagerStorageIndex =
      new LocalStorage('filemanager-index');
  final ButtonStyle outlineButtonStyle =
      OutlinedButton.styleFrom(primary: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if(widget.online)
                Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: OutlinedButton(
                        style: outlineButtonStyle,
                        onPressed: _createWhiteboard,
                        child: Text("Create Whiteboard"))),
            Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: OutlinedButton(
                    style: outlineButtonStyle,
                    onPressed: _createOfflineWhiteboard,
                    child: Text("Create Offline Whiteboard"))),
            Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: OutlinedButton(
                    style: outlineButtonStyle,
                    onPressed: _createFolder,
                    child: Text("Create Folder"))),
            if(widget.online)
                Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: OutlinedButton(
                        style: outlineButtonStyle,
                        onPressed: _collabOnWhiteboard,
                        child: Text("Collab on Whiteboard"))),
            if(widget.online)
                Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: OutlinedButton(
                        style: outlineButtonStyle,
                        onPressed: _importWhiteboard,
                        child: Text("Import Whiteboard"))),
          ],
        ),
      ),
    );
  }

  _createFolder() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => AddFolder(
            widget.authToken,
            widget.parent,
            widget._refreshController,
            widget.directories,
            widget.online),
      ),
    );
  }

  _createWhiteboard() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => AddWhiteboard(
            widget.authToken, widget.parent, widget._refreshController),
      ),
    );
  }

  _createOfflineWhiteboard() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => AddOfflineWhiteboard(
            widget.authToken,
            widget.parent,
            widget._refreshController,
            widget.offlineWhiteboards,
            widget.offlineWhiteboardIds),
      ),
    );
  }

  _collabOnWhiteboard() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => AddExtWhiteboard(
            widget.authToken, widget.parent, widget._refreshController),
      ),
    );
  }

  _importWhiteboard() async {
    FilePickerCross result = await FilePickerCross.importFromStorage(
        type: FileTypeCross.custom, fileExtension: 'json');
    await fileManagerStorage.ready;
    await fileManagerStorageIndex.ready;
    String json = new String.fromCharCodes(result.toUint8List());
    OfflineWhiteboard offlineWhiteboard =
        await OfflineWhiteboard.fromJson(jsonDecode(json));
    offlineWhiteboard.directory = widget.parent;
    await fileManagerStorage.setItem("offline_whiteboard-" + offlineWhiteboard.uuid,
        offlineWhiteboard.toJSONEncodable());
    Set<String> offlineWhiteboardIds = Set.of([]);
    try {
      offlineWhiteboardIds = Set.of(
          jsonDecode(fileManagerStorageIndex.getItem("indexes"))
                  .cast<String>() ??
              []);
    } catch (ignore) {
      offlineWhiteboardIds = Set.of([]);
    }
    offlineWhiteboardIds.add(offlineWhiteboard.uuid);
    await fileManagerStorageIndex.setItem(
        "indexes", jsonEncode(offlineWhiteboardIds.toList()));
    widget._refreshController.requestRefresh();
  }
}
