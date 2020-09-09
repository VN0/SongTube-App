// Flutter
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:songtube/internal/playerService.dart';
import 'package:songtube/screens/musicPlayer/screenStateStream.dart';
import 'package:transparent_image/transparent_image.dart';

class CollapsedPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ScreenState>(
      stream: screenStateStream,
        builder: (context, snapshot) {
        final screenState = snapshot.data;
        final mediaItem = screenState?.mediaItem;
        final state = screenState?.playbackState;
        final playing = state?.playing ?? false;
        if (mediaItem != null) {
          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: [
                // Song AlbumArt & Title and Author
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: EdgeInsets.only(left: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: FadeInImage(
                            height: 50,
                            width: 50,
                            fadeInDuration: Duration(milliseconds: 400),
                            placeholder: MemoryImage(kTransparentImage),
                            image: FileImage(File(mediaItem.artUri.replaceFirst("file://", ""))),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${mediaItem.title}",
                                style: TextStyle(
                                  fontFamily: 'Varela'
                                ),
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                maxLines: 1,
                              ),
                              Text(
                                "${mediaItem.album}",
                                style: TextStyle(
                                  fontFamily: 'Varela',
                                  fontSize: 10
                                ),
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                maxLines: 1,
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                // Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(MdiIcons.skipPreviousOutline),
                      onPressed: () => AudioService.skipToPrevious(),
                    ),
                    IconButton(
                      icon: playing
                        ? Icon(MdiIcons.pause, size: 25)
                        : Icon(MdiIcons.play, size: 25),
                      onPressed: playing
                        ? () => AudioService.pause()
                        : () => AudioService.play(),
                    ),
                    IconButton(
                      icon: Icon(MdiIcons.skipNextOutline),
                      onPressed: () => AudioService.skipToNext(),
                    )
                  ],
                )
              ],
            ),
          );
        } else {
          return Container();
        }
      }
    );
  }
}