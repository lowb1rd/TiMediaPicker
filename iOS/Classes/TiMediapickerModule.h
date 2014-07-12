/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiModule.h"
#import "KrollCallback.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface TiMediapickerModule : TiModule 
{
	KrollCallback *photosCallback;	
    KrollCallback *posterCallback;	
    KrollCallback *groupCallback;
    KrollCallback *groupCallbackError;
    KrollCallback *bytesCallback;
    KrollCallback *imageCallback;
	
    KrollCallback *loadedCallback;
    KrollCallback *thumbCallback;
    KrollCallback *assetUrlCallback;
	
	NSMutableArray *assetGroups;
	ALAssetsLibrary *library;
}

@end
