/**
 * TiMediaPicker
 *
 * Created by nils
 * Copyright (c) 2014 Your Company. All rights reserved.
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