/* Battery.m
 *  
 * Copyright (C) 2011 Andreas Schik
 *
 * Author: Andreas Schik <andreas@schik.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#import "Battery.h"


@interface Battery (Private)
    
- (NSString *) iconName;
- (NSString *) batteryStatusString;
- (void) updateData;

@end

@implementation Battery (Private)

/**
 * Calculate the battery icon name
 */
- (NSString *) iconName
{
    NSMutableString *imgName = [NSMutableString stringWithCapacity: 10];

    if ([[device IsPresent] boolValue] == YES) {
        if ((chargeState == STATE_FULL) && (percentage >= 99)) {
            [imgName setString: @"battery-charged"];
        } else if (chargeState == STATE_EMPTY) {
            [imgName setString: @"battery-empty"];
        } else {
            if (percentage > 90) {
                [imgName setString: @"battery-100"];
            } else if (percentage > 70) {
                [imgName setString: @"battery-080"];
            } else if (percentage > 50) {
                [imgName setString: @"battery-060"];
            } else if (percentage > 30) {
                [imgName setString: @"battery-040"];
            } else if (percentage > 10) {
                [imgName setString: @"battery-020"];
            } else {
                [imgName setString: @"battery-000"];
            }
            if (chargeState == STATE_CHARGING) {
                [imgName appendString: @"-charging"];
            }
        }
    } else {
        [imgName setString: @"battery-missing"];
    }
    return imgName;
}


/**
 * Composes a textual representation of the battery status. The string
 * tells us whether we run on AC power or on battery, what the fill
 * status is etc.
 */
- (NSString *) batteryStatusString
{
    NSMutableString *status = [NSMutableString new];

    if([self percentage] >= 0) {
        [status appendFormat: @"Battery %@ at %2d%%\n", [self name], [self percentage]];
    }
    if([self remainingTime] > 0) {
        if (chargeState == STATE_CHARGING) {
            [status appendFormat: @"%dm %02ds remaining until full",
                [self remainingTime]/60, [self remainingTime]%60];
        } else if (chargeState == STATE_DISCHARGING) {
            [status appendFormat: @"%dm %02ds remaining until empty",
                [self remainingTime]/60, [self remainingTime]%60];
        }
    }
    return [status autorelease];
}

- (void) updateData
{
    int oldPercentage = percentage;
    percentage = [[device Percentage] intValue];
    chargeState = [[device State] intValue];
    if (chargeState == STATE_CHARGING) {
        remainingTime = [[device TimeToFull] intValue];
    } else if (chargeState == STATE_DISCHARGING) {
        remainingTime = [[device TimeToEmpty] intValue];
    }

    NSDebugLog(@"Battery %@ changed: %@ at %d%%, remaining %d", name,
        chargeState == STATE_CHARGING
          ?@"charging"
          :(chargeState == STATE_DISCHARGING?@"discharging":@"charged"),
          percentage, remainingTime);
    if ((percentage < warningThreshold) && (oldPercentage >= warningThreshold)) {
        mustShowWarning = YES;
    }
}

@end

@implementation Battery

- (id) initFromDevice: (DKProxy *)proxy
            upHandler: (UpowerHandler *)handler
{
    self = [super init];
    if (self != nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        warningThreshold = [defaults integerForKey: @"warning_threshold"];
        if (warningThreshold <= 0) {
            warningThreshold = 10;
        }
        mustShowWarning = NO;
        percentage = 100;
        upHandler = handler;
        RETAIN(upHandler);
        device = (id <NSObject,DeviceProperties>)proxy;
        RETAIN(device);
        NSString *path = [device NativePath];
        name = [path lastPathComponent];
        RETAIN(name);
        [self updateData];
        NSString *imgName = [self iconName];
        biController = [[BatteryIconController alloc] initWithImage: imgName
                             andStatus: [self batteryStatusString]];
        [biController showTrayIcon];
        [upHandler registerPropertyChangedHandler: self forDevice: proxy];
    }
    return self;
}

-(void) dealloc
{
    [upHandler unregisterPropertyChangedHandler: self forDevice: (DKProxy *)device];
    DESTROY(name);
    DESTROY(device);
    DESTROY(biController);
    DESTROY(upHandler);
    [super dealloc];
}

- (NSString *) name
{
    return name;
}

- (int) percentage
{
    return percentage;
}

- (int) remainingTime
{
    return remainingTime;
}

- (void) propertyModified: (id)data
{
    [self updateData];
    NSString *imgName = [self iconName];
    [biController setImage: imgName andStatus: [self batteryStatusString]];

    // If the battery state changes we might need the emergency popup
    if (mustShowWarning) {
        mustShowWarning = NO;
        [biController showNotificationWithTitle: @"Battery status critical"
                                        message: [self batteryStatusString]
                                          image: imgName];
    }

}

@end

