/*
 *    BatteryIconController.m
 *
 *    Copyright (c) 2011
 *
 *    Author: Andreas Schik <andreas@schik.de>
 *
 *    This program is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program; if not, write to the Free Software
 *    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#import <AppKit/AppKit.h>
#import <DBusKit/DBusKit.h>

#import "BatteryIconController.h"


@protocol Notifications
- (NSNumber *) Notify: (NSString *) appname
                     : (uint) replaceid
                     : (NSString *) appicon
                     : (NSString *) summary
                     : (NSString *) body
                     : (NSArray *) actions
                     : (NSDictionary *) hints
                     : (int) expires;
@end

static NSString * const DBUS_BUS = @"org.freedesktop.Notifications";
static NSString * const DBUS_PATH = @"/org/freedesktop/Notifications";

static const long MSG_TIMEOUT = 10000;

static BOOL noTrayIcon = NO;

@interface BatteryIconController (Private)
- (NSImage *) getImage: (NSString *) image forSize: (int) size;
@end

@implementation BatteryIconController (Private)
- (NSImage *) getImage: (NSString *) image forSize: (int) size
{
    NSImage *img = nil;
    NSString *imgPath = nil;
    NSString *path = nil;
    NSBundle *bundle = [NSBundle bundleForClass: [self class]];

    imgPath = [NSString stringWithFormat: @"%d/%@", size, image];
    path = [bundle pathForResource: imgPath ofType: @"tiff"];
    if (nil != path) {
        img = [[NSImage alloc] initWithContentsOfFile: path];
    }
    if (nil != img) {
        NSColor *col = [NSColor colorWithCalibratedRed: 1.0
                              green: 1.0
                               blue: 1.0
                              alpha: 0.0];
        [img setBackgroundColor: col];
    }
    return AUTORELEASE(img);
}
@end


@implementation BatteryIconController

+ (void) initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    noTrayIcon = [defaults boolForKey: @"hide_tray_icon"];
}

/**
 * <p><init /></p>
 */
- (id) initWithImage: (NSString *)image andStatus: (NSString *)status
{
  self = [super init];
  if (self != nil) {
#ifndef NOTRAYICON
    if (!noTrayIcon) {
      NSBundle *bundle = [NSBundle bundleForClass: [self class]];
      NSString *imgPath = [NSString stringWithFormat: @"%@/16",
                              [bundle resourcePath]];
      tic = [[TrayIconController alloc] init];
      [tic setDefaultIconPath: imgPath];
      [tic createImage: image];
      [tic setTooltipText: status];
    }
#endif

    NSImage *img = [self getImage: image forSize: 48];
    [NSApp setApplicationIconImage: img];
    [[[NSApp iconWindow] contentView] setToolTip: status];
  }
  return self;
}


- (void) dealloc
{
#ifndef NOTRAYICON
    if (!noTrayIcon) {
        DESTROY(tic);
    }
#endif
    [super dealloc];
}

- (void) showTrayIcon
{
#ifndef NOTRAYICON
    if (!noTrayIcon) {
        [tic showTrayIcon];
    }
#endif
}

- (void) showMessage: (NSTimer *)timer
{
    NSDictionary *info = [timer userInfo];
    NSString *title = [info objectForKey: @"title"];
    NSString *message = [info objectForKey: @"message"];
    NSString *image = [info objectForKey: @"image"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults boolForKey: @"disable_notifications"] == YES) {
        return;
    }

    if ((message != nil) && ([message length] != 0)) {
        NSConnection *c;
        NSNumber *dnid;
        id <NSObject,Notifications> remote;
        BOOL handled = NO;

        // Try to deliver the message via DBus to a notification handler.
        // If this does not work display the message via the system tray.
        NS_DURING {
            c = [NSConnection
                connectionWithReceivePort: [DKPort port]
                                 sendPort: [[DKPort alloc] initWithRemote:DBUS_BUS]];

            if (c) {
                remote = (id <NSObject,Notifications>)[c proxyAtPath: DBUS_PATH];
                if (remote) {
                    NSBundle *bundle = [NSBundle bundleForClass: [self class]];
                    NSString *resPath = [NSString stringWithFormat: @"48/%@", image];
                    NSString *iconPath = [bundle pathForResource: resPath ofType: @"tiff"];

                    NSDictionary *hints = [NSDictionary dictionary];
                    dnid = [remote Notify: @"Battery" 
                                         : 0 
                                         : iconPath 
                                         : title 
                                         : message
                                         : [NSArray array] 
                                         : hints
                                         : MSG_TIMEOUT];
                    handled = YES;
                }
                [c invalidate];
            }
        }
        NS_HANDLER
        {
        }
        NS_ENDHANDLER
#ifndef NOTRAYICON
        if (!noTrayIcon && (handled == NO)) {
            [tic sendMessage: message timeout: MSG_TIMEOUT];
        }
#endif
    }
}

- (void) setImage: (NSString *) image andStatus: (NSString *) status
{
#ifndef NOTRAYICON
    if (!noTrayIcon) {
        [tic setIcon: image];
        [tic setTooltipText: status];
    }
#endif

    NSImage *img = [self getImage: image forSize: 48];
    [NSApp setApplicationIconImage: img];
    [[[NSApp iconWindow] contentView] setToolTip: status];
}

- (void) showNotificationWithTitle: (NSString *)title
                           message: (NSString *)message
                             image: (NSString *)image
{
    CREATE_AUTORELEASE_POOL(pool);

    // For some reason the icon is not displayed properly
    // if we send the message directly. Hence we set up a
    // timer to display the systray message with a slight delay.
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
        message, @"message", title, @"title", image, @"image", nil];
    [NSTimer scheduledTimerWithTimeInterval: 0.2
                                     target: self
                                   selector: @selector(showMessage:)
                                   userInfo: info
                                    repeats: NO];
    RELEASE(pool);
}

@end
