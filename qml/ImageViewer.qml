/*
 * Copyright (C) 2014 Vishesh Handa <vhanda@kde.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) version 3, or any
 * later version accepted by the membership of KDE e.V. (or its
 * successor approved by the membership of KDE e.V.), which shall
 * act as a proxy defined in Section 6 of version 3 of the license.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import QtQuick 2.3
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.0 as QtControls

import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
    id: root
    clip: true

    /**
     * An optional model which contains all the Images. This is used
     * to change the index during Key Navigation
     */
    property var model
    property int currentIndex
    signal deleteImage(string filePath, int index)
    signal listEmpty()

    Rectangle {
        color: "#646464"
        anchors.fill: parent
        z: -1
    }

    property string filePath
    onFilePathChanged: {
        img.rotation = 0
        resetImageSize()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentWidth: img.width < flick.width ? flick.width : img.width
            contentHeight: img.height < flick.height ? flick.height : img.height
            boundsBehavior: Flickable.StopAtBounds
            Image {
                id: img
                source: root.filePath
                fillMode: Image.PreserveAspectFit

                width: flick.width
                height: flick.height
                mipmap: true

                anchors.centerIn: parent
            }

            onWidthChanged: resetImageSize()
        }

        ClipRectangle {
            id: clipRect
            source: img
            visible: false
        }

        // Tool bar
        Rectangle {
            SystemPalette { id: sysPal; }
            color: sysPal.window
            Layout.fillWidth: true
            Layout.maximumHeight: 60
            Layout.minimumHeight: 60

            RowLayout {
                anchors.fill: parent
                PlasmaComponents.ToolButton {
                    iconName: "object-rotate-left"
                    onClicked: img.rotation = img.rotation - 90
                }
                PlasmaComponents.ToolButton {
                    iconName: "object-rotate-right"
                    onClicked: img.rotation = img.rotation + 90
                }
                PlasmaComponents.ToolButton {
                    iconName: "transform-crop"
                    onClicked: {
                        clipRect.visible = !clipRect.visible
                        // Marking the button as in use. It's an ugly way
                        flat = !clipRect.visible
                        // Reset the clip rectangle?
                        deleteButton.enabled = !clipRect.visible
                        // disables the deleteButton while cropping
                    }
                }
                PlasmaComponents.ToolButton {
                    id: "deleteButton"
                    iconName: "albumfolder-user-trash"
                    onClicked: imageDelete(model[currentIndex], currentIndex)
                }

                // Spacer
                Item {
                    Layout.fillWidth: true
                }

                // Zoom
                QtControls.Button {
                    text: "Fit"
                    onClicked: {
                        img.width = flick.width
                        img.height = flick.height
                    }
                }
                QtControls.Button {
                    text: "100%"
                    onClicked: {
                        img.width = img.sourceSize.width
                        img.height = img.sourceSize.height
                    }
                }
                QtControls.ToolButton {
                    iconName: "file-zoom-out"
                    onClicked: slider.value = slider.value - 1.0
                }
                QtControls.Slider {
                    id: slider
                    minimumValue: 1.0
                    maximumValue: 9.99
                    value: 1.0

                    Layout.alignment: Qt.AlignRight

                    onValueChanged: {
                        img.width = img.sourceSize.width * value
                        img.height = img.sourceSize.height * value
                    }
                }
                QtControls.ToolButton {
                    iconName: "file-zoom-in"
                    onClicked: slider.value = slider.value + 1.0
                }
                QtControls.Label {
                    text: Math.floor(img.width/img.sourceSize.width * 100) + "%"
                }
            }
        }
    }

    Keys.onRightPressed: nextImage()
    Keys.onLeftPressed: previousImage()

    function nextImage() {
        currentIndex = Math.min(model.length - 1, currentIndex + 1)
        filePath = model[currentIndex]
    }
    function previousImage() {
        currentIndex = Math.max(0, currentIndex - 1)
        filePath = model[currentIndex]
    }
    function hasNextImage() {
        return currentIndex < model.length - 1;
    }
    function hasPreviousImage() {
        return currentIndex > 0;
    }

    function resetImageSize() {
        //
        // This is done so that if the Image is naturally smaller, we show its
        // original size, instead of scaling it up.
        //
        if (flick.width > img.sourceSize.width) {
            img.width = img.sourceSize.width
            img.height = img.sourceSize.height
        } else {
            img.width = flick.width
            img.height = flick.height
        }
    }
    
    function imageDelete(filePath, index){
        deleteImage(filePath,index)
        if(root.hasNextImage()){
            root.nextImage()            
        } else if(root.hasPreviousImage()){
            root.previousImage();
        } else {
            listEmpty()
            return 
        }
        model.splice(index,1)
    }
}
