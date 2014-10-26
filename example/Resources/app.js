Ti.UI.setBackgroundColor('#fff');

var MediaPickerModule = require('/MediaPicker').MediaPicker;
var MediaPicker = new MediaPickerModule();
var win = Ti.UI.createWindow();
var sv = Ti.UI.createScrollableView({top: 50});
var iOS = Ti.Platform.osname == 'iphone' || Ti.Platform.osname == 'ipad';

var buttonImage = Ti.UI.createButton({
	title: 'Choose Images',   
	width: '50%',
	left: 0, top: 20,
});
buttonImage.addEventListener('click', function() {
	var callback = function(items) {
		var views = [];
		var iterate = function(item) {
			MediaPicker.getImageByURL({
				key: item.url,
				id: item.id,
				success: function(e) {
					views.push(Ti.UI.createImageView({image: e.image.apiName == 'Ti.Blob' ? e.image : 'file://'+e.image}));
					if (items.length) iterate(items.splice(0,1)[0]);
					else {
						sv.views = views;
						if (!sv.added) win.add(sv);
						sv.added = true;
					}
				}
			});			
		}
		if (items.length) iterate(items.splice(0,1)[0]);
	};
	MediaPicker.show(callback, 4, 'photos', 'Choose up to four images! Longlick image for preview.');
});
win.add(buttonImage);

var buttonVideo = Ti.UI.createButton({
	title: 'Choose Video',   
	width: '50%',
	right: 0, top: 20,
});
buttonVideo.addEventListener('click', function() {
	var callback = function(video) {
		if (!video[0]) return;
		var player = Ti.Media.createVideoPlayer({
			backgroundColor:'#fff',
			autoplay : true,
			mediaControlStyle : Titanium.Media.VIDEO_CONTROL_DEFAULT,
			scalingMode : Titanium.Media.VIDEO_SCALING_ASPECT_FIT,			
		});
		if (iOS) player.media = video[0].url;
		else player.url = 'file://' + video[0].url;
		player.addEventListener('complete', function(e) {
			player.release();
			if (iOS) win.remove(player);
			player = null;
		});
		if (iOS) win.add(player);
		
	};
	MediaPicker.show(callback, 1, 'videos', 'Choose a video! Longlick video for preview.');
});
win.add(buttonVideo);

win.open();


// Get the full media file
// On Android, the path of the media can be used to get a file handle
// On iOS, the assetURL cannot be used to get a file handle/blob for the media directly
// The method getBytesByURL copies the asset into a temp file and returns the path to this tempfile
/*
var MediaPickerNative = require('ti.mediapicker');
if (iOS) {
    MediaPickerNative.getBytesByURL({
        key: item.url,
        success: function(res) {
            var file = Ti.Filesystem.getFile(res.path);
            // for XHR upload do this
			send_array.data = file.toBlob()			
            // delete the file once the opload is complete with file.delete()
            // only do this on iOS since on Android the file points to the real file, not a temporary copy
        }
    });				
} else {
    var file = Ti.Filesystem.getFile('file://'+item.url);
    // for XHR upload do this (it streams the file directly from disk)
    send_array.data = file;
}
*/
