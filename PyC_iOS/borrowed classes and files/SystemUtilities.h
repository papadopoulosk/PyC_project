//
//  SystemUtilities.h
//  SystemUtilities
//
//  Created by Tom Markel on 5/2/12.
//  Copyright (c) 2012 MarkelSoft, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>
#import <ExternalAccessory/EAAccessoryManager.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#import <arpa/inet.h>
#include <errno.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#import <sys/sysctl.h>  
#import <sys/utsname.h>
#import <sys/times.h>
#import <sys/stat.h>
#import <sys/_structs.h>
#import <asl.h>
#import <ifaddrs.h>
#import <mach/mach.h>
#import <mach/mach_host.h>
#include <stdio.h>

#import "IPAddress.h"

@interface SystemUtilities
    
// System Utility Functions

+ (NSString *)getSystemUptime;    // system uptime in days, hours, minutes e.g. 1d 0h 7min

+ (NSString *)getProcessorInfo;   // procssor information including number of processors and number of processors active
+ (NSString *)getCPUFrequency;    // processor CPU speed (MHz)
+ (NSString *)getBusFrequency;    // processor BUS speed (MHz)

+ (NSString *)getAccessoryInfo;   // information on any accessories attach to the device

+ (NSString *)getCarrierInfo;     // phone carrier information including carrier name, carrier country and whether VOIP is allowed 
+ (NSString *)getCarrierName;     // phone carrier name
+ (NSString *)getCarrierMobileCountryCode;  // phone carrier mobile country code
+ (NSString *)getCarrierISOCountryCode;     // phone carrier ISO country code
+ (NSString *)getCarrierMobileNetworkCode;  // phone carrier mobile network code
+ (BOOL)doesCarrierAllowVOIP;     // whether phone carrier allows VOIP (Voice over IP)
+ (NSString * )getMCC_country:(NSString *)carrierMobileCountryCode;  // mobile country for mobile country code
+ (NSString *)getCountry:(NSString *)_countryCode;  // country for country code

+ (NSString *)getBatteryLevelInfo;  // battery level information including percent charges and whether plugged in and charging
+ (float)getBatteryLevel;           // battery level percentage charged

+ (NSString *)getUniqueIdentifier;  // unique identifier for the device

+ (NSString *)getModel;             // model of the device
+ (NSString *)getName;              // name identifying the device
+ (NSString *)getSystemName;        // name the operating system (OS) running on the device
+ (NSString *)getSystemVersion;     // current version of the operating system (OS)

+ (NSString *)getDeviceType;        // device type e.g. 'iPhone4,1' for 'iPhone 4' and 'iPad3,3' and 'New iPad'
+ (NSString *)getRealDeviceType;    // real device type e.g. 'iPhone4,1' real device type is 'iPhone 4'
+ (NSString *)getDeviceTypeAndReal; // device type and real device type e.g. 'iPhone 4,1 iPhone 4'

+ (BOOL)onWifiNetwork;               // Detemine if on Wifi network.  TRUE - yes, FALSE - no
+ (BOOL)on3GNetwork;                 // Determine if on a 3G (or 4G) network,  TRUE - yes, FALSE - no
+ (NSMutableArray *)getMacAddresses; // MAC (Media Access Control) addresses    
+ (NSString *)getCellAddress;        // Cell phone IP address (on 4G, 3G etc. network.  Note: getMacAddresses must be called beore getCellAddress)
+ (NSString *)getIPAddress;          // Device IP address on 
+ (NSString *)getIPAddressForWifi;   // IP address for Wifi
+ (NSString *)getNetmaskForWifi;     // Network mask for Wifi
+ (NSString *)getBroadcastForWifi;   // Boardcast IP address or Wifi

+ (NSMutableArray *)getAppLog:(NSString *)_name verbose:(BOOL)_verbose;  // Application log for a specific application

+ (NSMutableArray *)getProcessInfo;  // Process information including PID (process ID), process name, PPID (paren process ID) and status
+ (int)getParentPID:(int)pid;        // PID (parent ID) for a PID (process ID)

+ (NSString *)getDiskSpace;           // Total disk space formatted
+ (NSString *)getFreeDiskSpace;       // Free disk space formatted
+ (NSString *)getFreeDiskSpaceAndPct; // Free disk and percent disk free formatted
+ (NSString *)getFreeDiskSpacePct;    // Disk space free percentage formatted
+ (NSString *)getFreeMemoryPct;       // Free memory percentage formatted
+ (NSString *)getUsedMemoryPct;       // Used memory percentage formatted
+ (long long)getlDiskSpace;           // Total disk space
+ (long long)getlFreeDiskSpace;       // Free disk space

+ (double)getFreeMemory;              // Free memory
+ (double)getTotalMemory;             // Total memory
+ (double)getUsedMemory;              // Used memory
+ (double)getAvailableMemory;         // Availoable memory
+ (double)getActiveMemory;            // Active memory (used by running apps)
+ (double)getInActiveMemory;          // Inactive memory (recently used by apps no loger running)
+ (double)getWiredMemory;             // Wired memory (used by OS)
+ (double)getPurgableMemory;          // Puragable memory (can be freed)

+ (BOOL)isRunningIPad;                // Determine if device running iPad.  TRUE - running iPad, FALSE running iPhone, iPod Touch, ...
+ (BOOL)isIPhone;                     // Determine if device is an iPhone
+ (BOOL)isIPhone4;                    // Determine if device running is an iPhone 4
+ (BOOL)doesSupportMultitasking;      // Determine if device supports multitasking. TRUE - yes, FALSE - no
+ (BOOL)isProximitySensorAvailable;   // Determine if proximity sensor is available for the device.   TRUE - yes, FALSE - no


// utility method for loading country codes
+ (void)loadCodes;

+ (NSString *)formatBytes:(int)_number;
+ (NSString *)formatBytes2:(long long)_number;
+ (NSString *)formatDBytes:(double)_number;
+ (NSString *)formatNumber:(int)_number;
+ (NSString *)formatNumber2:(unsigned long long)_number;
+ (NSTimeInterval)uptime:(NSNumber **)days hours:(NSNumber **)hours mins:(NSNumber **)mins;

+ (NSString *)broadcastAddressForAddress:(NSString *)ipAddress withMask:(NSString *)netmask;
+ (NSString *)ipAddressForInterface:(NSString *)ifName;
+ (NSString *)ipAddressForWifi;
+ (NSString *)netmaskForInterface:(NSString *)ifName;
+ (NSString *)netmaskForWifi;

@end
