# TiMediaPicker

**Titanium Mobile MediaPicker Module for iOS and Android**

This module shows the gallery of the phone and allows selecting single or multiple Media Files (Images or Videos).  

On iOS, the ALAssets Library is used for accessing the media files. On Android the MediaStore is used to query for media files on the device. Only the media information is fetched in the native part of the module. The complete picker UI is done by a CommonJS Titanium module in pure Javascript and is therefor easy customizable.

## Features

- Landscape and Portrait Orientation support
- Fastscroll support for large galleries
- UI build completely in JavaScript

## Performance Considerations and Platform Differences

This picker was tested with galleries of 1000+ images. Performance was the main concern while developing the module. To achive a good performance on both platforms, some things had to be done differently between them. These implementation differences are descibed below.

### Different Data Types for Images
On Android, all image sizes (Thumb, Fullscreen, Full) are returned as a file path (String). On iOS, only the "Full" image is available as a file path (asset://). All other image types are returned as a Blob (TiBlob).

### TableView vs. Scrollview
Tests have shown that under iOS, a lazy loading table view (that is appending rows via appendRow() dynamically on scrolling) performs best. On Android a ScrollView as container shows the best performance. (GridView would be even better but it's not available as a Titanium API. The new Titanium ListView is not (yet) powerful enough to display a grid dynamically).

### Android Thumbnail Cache

There are two kinds of thumbnails on Android. MICRO_KIND are very small thumbnails stored in the MediaStore as a blob. MINI_KIND are larger thumbnails stored on the filesystem and are therefor available as a file path.
Using the MICRO_KIND blobs as a thumb source caused weird caching issues with Titanium. Some images were randomly replaced with previously loaded images when scrolling up and down through the list of photos. For some reason, Titanium does handle lots of images with blobs as a source in a ScrollView not very well. The solution is to not use blobs but file paths as image sources instead. Because of this, the native module returns always the path to the MINI_KIND thumbnails.
Since using the rather large MINI_KIND thumbs performs badly in a huge ScrollView, all thumbnails are reduced in size and cached in the applications temp directory for performance reasons. The path to that tmp directory is used as thumb source in the ScrollView. This caching is done in the CommonJS part of the module and can therefor easily be disabled.

### Thumbnail Unloading and Memory Management
Under Android, all Thumbnails are unloaded once they are out of view to free memory and keep the performance of the ScrollView good. On iOS, the unloading is not neccessary since the TableView performs well even with 1000+ images (memory management is done internally here I guess).

### Meta Information
All returned thumbnails include meta information such as the original dimensions, size in bytes and duration (for videos).

Since the size information (in bytes) of a photo/video is not needed in the gridview, this meta information is only fetched when the image has been picked.

Android 2.3.3 does not store the image dimensions in the MediaStore. To get these information, every single photo would have to be loaded in a BitmapFactory. Because this kills the performance totally, the dimensions meta information is not available in the GridView for Android 2.3.3. In this case, the meta information is fetched later when the image was picked.

## Example app.js and CommonJS Module MediaPicker.js

This module comes with an example CommonJS module that accesses the methods of the native modules and builds the picker UI. The CommonJS module also demonstrates how to use the available meta information to display certain indicators right on the thumbs. So does a small grey rectangle indicate the orientation (landscape or portrait) of the original image. A warning icon is shown for small images. Since all this is done in the CommonJS module, the UI is easily customizable.
The app.js shows a minimal use case for the complete module. All picked images are simply loaded into a ScrollAble view for demonstration purposes.

## Reference

### MediaPicker.js
#### MediaPicker.show(callback, maximum, type, message)
**Opens the picker view. Parameters:**
*callback* is called once media has been selected. The selected items are given as an array to the callback function. Every array value is an object containing the following information:
  - *url* asset:// or filepath to the original image
  - *id* android only, image ID
  - *metadata* Object with width, height and duration (video only)
*maximum* maximum number of selectable assets. Once this limit is reached, an alert message is shown. If this limit is 1, the previously selected image is automatically deselected
*type* "photos" or "videos"
*message* optional. A message bar displayed at the top of the grid

#### MediaPicker.getImageByURL(options)
**This is just a wrapper for the getImageByURL of the native module to make the call the same on both platforms.**

### Module
#### getAssetGroups(options)
**Gets all galleries / asset groups.**
options {
	type: "photos" or "videos"
	success: callback function {
		key : {
			name: The name of the gallery
			count: The number of files in this gallery
			image: Blob, preview image for the gallery
		},
		..
	}
}

#### getThumb(options)
**Gets a single Thumbnail**
options {
	url: image id (android) or asset url (ios)
	success: {
		image: blob or file path to thumb
		width: image width in pixels (iOS only)
		height: image height in pixels (iOS only)
		duration: video duration in seconds (iOS only)
		size: video size in bytes (iOS only)
	}
}

#### getPhotos(options)
**Returns all image information in a certain gallery**
options {
	nr: the gallery to query. identified by the key (android) or sequential number (ios)
	type: "photos" or "videos"
	success: callback function {
		items: [
			{
				width: image width in pixels (android > 2.3.3 only)
				height: image height in pixels (android > 2.3.3 only)
				duration: video duration in seconds (android > 2.3.3 only)
			},
			..
		]
	}
}

#### getBytesByURL(options)
**iOS only. Used to get the original (full) asset by assetURL. On android, the file path can be used direcly to get the file.**
options {
	key: assetURL of the media
	success: callback function {
		path: path to the full asset in tmp directory. can be used with Ti.Filesystem.getFile()
	}
}

#### getImageByURL(options, payload)
**Get the FullScreenImage / large thumbnail of an asset. On android a payload object can be passed as a second argument. On iOS the payload is a key of the options object.**
options: {
	key: assetURL / path of the media
	id: ID of the media (android only)
	payload: Object, passed back to success callback
	success: callback function {
		image: blob or file path
		width: image width in pixels
		height: image height in pixels
		size: size in bytes
	}
}