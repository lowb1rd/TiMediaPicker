/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiMediapickerModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "KrollCallback.h"

@implementation TiMediapickerModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"741238c8-4420-4949-9a8c-beefcd8fda56";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"ti.mediapicker";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];

	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably

	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup

-(void)dealloc
{
	// release any resources that have been retained by the module
	[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
	if (count == 1 && [type isEqualToString:@"my_event"])
	{
		// the first (of potentially many) listener is being added
		// for event named 'my_event'
	}
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
	if (count == 0 && [type isEqualToString:@"my_event"])
	{
		// the last listener called for event named 'my_event' has
		// been removed, we can optionally clean up any resources
		// since no body is listening at this point for that event
	}
}

#pragma Public APIs
-(void)getAssetGroups:(id)args {
	ENSURE_UI_THREAD_1_ARG(args);
	ENSURE_SINGLE_ARG(args,NSDictionary);

	id ongroup	   = [args objectForKey:@"success"];
	id ongrouperror  = [args objectForKey:@"error"];
	NSString *group = [args objectForKey:@"group"];
	ENSURE_STRING_OR_NIL(group);

	NSString *type = [args objectForKey:@"type"];
	ENSURE_STRING_OR_NIL(type);

	NSUInteger groupTypes = ALAssetsGroupSavedPhotos;
	if( group == nil ){
		group = @"all";
	}
	if( [group isEqualToString:@"savedPhotos"] ){
		groupTypes  = ALAssetsGroupSavedPhotos;
	} else if( [group isEqualToString:@"photoStream"] ){
		groupTypes  = ALAssetsGroupPhotoStream;
	} else if( [group isEqualToString:@"faces"] ){
		groupTypes  = ALAssetsGroupFaces;
	} else if( [group isEqualToString:@"all"] ){
		groupTypes  = ALAssetsGroupAll;
	}

	RELEASE_TO_NIL(assetGroups);
	assetGroups  = [[NSMutableArray alloc] init];

	NSMutableArray *events = [[NSMutableArray alloc] init];

	RELEASE_TO_NIL(groupCallback);
	groupCallback  = [ongroup retain];
	RELEASE_TO_NIL(groupCallbackError);
	groupCallbackError  = [ongrouperror retain];
	void (^assetGroupEnumerator) (ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop){
		if(group != nil) {
			if ([type isEqualToString:@"videos"]) {
				[group setAssetsFilter:[ALAssetsFilter allVideos]];
			} else {
				[group setAssetsFilter:[ALAssetsFilter allPhotos]];
			}

			CGImageRef iref = [group posterImage];
			UIImage *poster;
			poster = [UIImage imageWithCGImage:iref];
			NSString * groupName = [group valueForProperty:ALAssetsGroupPropertyName];


			NSDictionary *event = [NSDictionary
								   dictionaryWithObjectsAndKeys:
								   groupName,
								   @"name",
								   [[[TiBlob alloc] initWithImage:poster] autorelease],
								   @"image",
								   NUMINT([group numberOfAssets]),
								   @"count",
								   nil];
			[events addObject:event];
			[assetGroups addObject:group];
		} else {
			if (groupCallback!=nil)
			{
				NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:events,@"items", nil];
				[self _fireEventToListener:@"onGroup" withObject:event listener:groupCallback thisObject:nil];
				[events release];
			}
		}
	};
	RELEASE_TO_NIL(library);
	library  = [[ALAssetsLibrary alloc] init];

	[library enumerateGroupsWithTypes:groupTypes
						   usingBlock:assetGroupEnumerator
						 failureBlock:^(NSError *error) {
							[self _fireEventToListener:@"onGroupError" withObject:nil listener:groupCallbackError thisObject:nil];
						 }];
	//[library release];
}

-(void)getThumb:(id)args {
	ENSURE_UI_THREAD_1_ARG(args);
	ENSURE_SINGLE_ARG(args,NSDictionary);


	NSString *url = [args objectForKey:@"url"];

	id success = [args objectForKey:@"success"];
	ENSURE_TYPE(success, KrollCallback);


	ALAssetsLibrary* assetsLib = [[ALAssetsLibrary alloc] init];


	NSURL *assetUrl = [NSURL URLWithString:url];
	[assetsLib assetForURL:assetUrl resultBlock:^(ALAsset *result) {
		if (result == nil) {
			//NSDictionary *obj = [NSDictionary dictionaryWithObject:@"requested asset cannot be found" forKey:@"error"];
			//[self _fireEventToListener:@"error" withObject:obj listener:errorCb thisObject:nil];
			return;
		}


		UIImage *thumbnail = [UIImage imageWithCGImage:[result thumbnail]];
		CGSize newSize = CGSizeMake(150, 150);
		UIGraphicsBeginImageContext(newSize);
		[thumbnail drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
		UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		NSMutableDictionary *res = [[NSMutableDictionary alloc] init];
		[res setObject:[[[TiBlob alloc] initWithImage:newImage] autorelease] forKey:@"image"];

		ALAssetRepresentation *rep = [result defaultRepresentation];
		CGSize imageSize = [rep dimensions];
		[res setObject:[NSNumber numberWithFloat:imageSize.width] forKey:@"width"];
		[res setObject:[NSNumber numberWithFloat:imageSize.height] forKey:@"height"];

		if ([result valueForProperty:ALAssetPropertyDuration] != ALErrorInvalidProperty) {
			[res setObject:[result valueForProperty:ALAssetPropertyDuration] forKey:@"duration"];

			NSUInteger size = [rep size];
			[res setObject:[NSNumber numberWithFloat:size] forKey:@"size"];
		}


		//[thumbnail release];
		//[newImage release];

		[self _fireEventToListener:@"gotAsset" withObject:res listener:success thisObject:nil];
		[res release];

	} failureBlock:^(NSError *error) {

		//NSDictionary *obj = [NSDictionary dictionaryWithObject:error.description forKey:@"error"];
		//[self _fireEventToListener:@"error" withObject:obj listener:errorCb thisObject:nil];
	}];

	assetsLib = nil;
}

-(void)getPhotos:(id)args {
	ENSURE_UI_THREAD_1_ARG(args);
	ENSURE_SINGLE_ARG(args,NSDictionary);

	int nr = [TiUtils intValue:[args objectForKey:@"nr"] def:0];
	NSString *type = [args objectForKey:@"type"];

	id success = [args objectForKey:@"success"];

	RELEASE_TO_NIL(photosCallback);
	photosCallback  = [success retain];

	ALAssetsGroup *assetGroup = [assetGroups objectAtIndex:nr];
	NSMutableArray *assets = [[NSMutableArray alloc] init];

	[assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
		if (result!= nil) {
			ALAssetRepresentation *rep = [result defaultRepresentation];
			NSURL *url = [rep url];
			NSString *sUrl = [url absoluteString];

			NSDictionary *event = [NSMutableDictionary
								   dictionaryWithObjectsAndKeys:
								   sUrl,
								   @"url",
								   nil];

			[assets addObject:event];
		}
	}];

	NSMutableDictionary *res = [[NSMutableDictionary alloc] init];
	[res setObject:assets forKey:@"items"];

	[self _fireEventToListener:@"onPhotos" withObject:res listener:photosCallback thisObject:nil];
	[res release];
	[assets release];
}

-(void)getBytesByURL:(id)args{
	ENSURE_UI_THREAD_1_ARG(args);
	ENSURE_SINGLE_ARG(args,NSDictionary);

	NSURL *url = [NSURL URLWithString:[args objectForKey:@"key"]];

	id success = [args objectForKey:@"success"];
	RELEASE_TO_NIL(bytesCallback);
	bytesCallback = [success retain];

	ALAssetsLibrary* lib = [[[ALAssetsLibrary alloc] init] autorelease];

	NSString * surl = [url absoluteString];
	NSString * ext = [surl substringFromIndex:[surl rangeOfString:@"ext="].location + 4];
	NSTimeInterval ti = [[NSDate date]timeIntervalSinceReferenceDate];
	NSString * filename = [NSString stringWithFormat: @"%f.%@",ti,ext];
	NSString * tmpfile = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];

	[lib assetForURL:url resultBlock:^(ALAsset *asset) {
		ALAssetRepresentation *rep = [asset defaultRepresentation];
		NSUInteger size = [rep size];
		const int bufferSize = 8192;

		NSLog(@"Writing to %@",tmpfile);
		FILE* f = fopen([tmpfile cStringUsingEncoding:1], "wb+");
		if (f == NULL) {
			NSLog(@"Can not create tmp file.");
			return;
		}

		Byte * buffer = (Byte*)malloc(bufferSize);
		int read = 0, offset = 0, written = 0;
		NSError* err;
		if (size != 0) {
			do {
				read = [rep getBytes:buffer
						  fromOffset:offset
							  length:bufferSize
							   error:&err];
				written = fwrite(buffer, sizeof(char), read, f);
				offset += read;
			} while (read != 0);
		}
		fclose(f);

		NSMutableDictionary *res = [[NSMutableDictionary alloc] init];
		[res setObject:tmpfile forKey:@"path"];

		if (bytesCallback != nil) {
			[self _fireEventToListener:@"success" withObject:res listener:bytesCallback thisObject:nil];
			[res release];
		}
	} failureBlock:^(NSError *error) {

	}];
}

-(void)getImageByURL:(id)args {
	ENSURE_UI_THREAD_1_ARG(args);
	ENSURE_SINGLE_ARG(args,NSDictionary);

	NSURL *url = [NSURL URLWithString:[args objectForKey:@"key"]];
	NSDictionary *payload = [args objectForKey:@"payload"];

	id success = [args objectForKey:@"success"];
	RELEASE_TO_NIL(imageCallback);
	imageCallback = [success retain];

	ALAssetsLibrary* lib = [[[ALAssetsLibrary alloc] init] autorelease];
	[lib assetForURL:url resultBlock:^(ALAsset *asset) {
		NSMutableDictionary *res = [[NSMutableDictionary alloc] init];
		ALAssetRepresentation *rep = [asset defaultRepresentation];
		UIImage *image;
		image = [UIImage imageWithCGImage:[rep fullScreenImage]];
		TiBlob* blob = [[[TiBlob alloc] initWithImage:image] autorelease];

		[res setObject:blob forKey:@"image"];

		NSUInteger size = [rep size];
		[res setObject:[NSNumber numberWithFloat:size] forKey:@"size"];
		CGSize imageSize = [rep dimensions];
		[res setObject:[NSNumber numberWithFloat:imageSize.width] forKey:@"width"];
		[res setObject:[NSNumber numberWithFloat:imageSize.height] forKey:@"height"];

		if (payload != nil) {
			[res setObject:payload forKey:@"payload"];
		}

		if (imageCallback!=nil) {
			[self _fireEventToListener:@"success" withObject:res listener:imageCallback thisObject:nil];
			[res release];
		}

	} failureBlock:^(NSError *error) {

	}];
}

@end

