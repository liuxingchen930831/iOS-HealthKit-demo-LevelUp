//
//  ViewController.m
//  HealthKit
//
//  Created by liuxingchen on 16/10/21.
//  Copyright © 2016年 Liuxingchen. All rights reserved.
//

#import "ViewController.h"
#import <HealthKit/HealthKit.h>
@interface ViewController ()
/**
 * 行走步数
 */
@property (weak, nonatomic) IBOutlet UILabel *labelCount;

@property (nonatomic, strong) HKHealthStore *healthStore;

@property(nonatomic,copy)NSString * currentTime ;

@property (weak, nonatomic) IBOutlet UILabel *todayStep;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    //查看healthKit在设备上是否可用
    if (![HKHealthStore isHealthDataAvailable])
    {
        NSLog(@"设备不支持healthKit");
    }
    self.currentTime = [self DateWithNowTimeString];
    
    
}

-(NSString *)DateWithNowTimeString
{
    //时间格式化
    
    NSDate *now = [NSDate date];
    
    //创建一个时间格式化对象
    
    NSDateFormatter
    *formatter = [[NSDateFormatter alloc]init];
    
    //按照什么样的格式来格式化时间
    
    formatter.dateFormat= @"yyyy-MM-dd";
    
    //利用时间格式化对象对时间进行格式化
    
    NSString * nowTime = [formatter stringFromDate:now];
    
    return nowTime;
}
- (IBAction)getHealthStore:(id)sender
{
    [self setupHealthStore];
}
//1.获取权限
-(void)setupHealthStore
{
    self.healthStore = [[HKHealthStore alloc]init];
    //设置需要获取的权限(获取步数、心跳、身高...)这里获取步数
    HKObjectType * stepCount = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    NSSet *healthSet = [NSSet setWithObjects:stepCount, nil];
    //health应用中获取权限 
    [self.healthStore requestAuthorizationToShareTypes:nil readTypes:healthSet completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"success");
        }else{
            NSLog(@"error");
        }
    }];
    
}

- (IBAction)moveCount:(id)sender
{
    [self readStepCount];
}

//2.读取步数
-(void)readStepCount
{   //查询的基类是HKQuery，这是抽象出来的类，能够实现每一种查询目标
    /**
     *  quantityTypeForIdentifier:这个方法需要传入一个采样信息(步数、心跳、身高...)
     */
    //查询采样信息
    HKSampleType *samleType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    //NSSortDescriptors用来告诉healthStore
    NSSortDescriptor *start = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    NSSortDescriptor *end = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    /**
     SampleType:样本检查类型
     predicate:未知
     limit:样品返回的最大数量。参数为HKObjectQueryNoLimit没有限制
     sortDescriptors:未知
     */
    HKSampleQuery * sampleQuery = [[HKSampleQuery alloc]initWithSampleType:samleType predicate:nil limit:HKObjectQueryNoLimit sortDescriptors:@[start,end] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        
        NSLog(@"resultCtount = %ld  result = %@",results.count ,results);
        
        //获取全部历史步数
        int sum=0;
        for (int i=0; i<results.count; i++) {
            HKQuantitySample *result = results[i];
            HKQuantity *quantity = result.quantity;
            NSString *stepStr = (NSString *)quantity;
            NSLog(@"stepStr = %@",stepStr);
            NSString *aaaa = [[NSString stringWithFormat:@"%@",stepStr] stringByReplacingOccurrencesOfString:@" count" withString:@""];
            sum+= [aaaa intValue];
 
    }
        
//        //对结果进行单位换算
//        HKQuantitySample * result = results[0];
//        HKQuantity *quantity = result.quantity;
//        NSString *string = (NSString *)quantity;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.labelCount.text = [NSString stringWithFormat:@"历史计步%d",sum];
        }];
        
    }];
    [self.healthStore executeQuery:sampleQuery];
}
- (IBAction)clickReadTodayStep:(id)sender {
    [self readTodayStep];
}
//查询当天步数
-(void)readTodayStep
{
    //查询采样信息
    HKSampleType *sampleType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    //NSSortDescriptor来告诉healthStore怎么样将结果排序
    NSSortDescriptor *start = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    NSSortDescriptor *end = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    //获取当前时间
    NSDate *now = [NSDate date];
    NSCalendar *calender = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *dateComponent = [calender components:unitFlags fromDate:now];
    int hour = (int)[dateComponent hour];
    int minute = (int)[dateComponent minute];
    int second = (int)[dateComponent second];
    NSDate *nowDay = [NSDate dateWithTimeIntervalSinceNow:  - (hour*3600 + minute * 60 + second) ];
    //时间结果与想象中不同是因为它显示的是0区
    NSLog(@"今天%@",nowDay);
    NSDate *nextDay = [NSDate dateWithTimeIntervalSinceNow:  - (hour*3600 + minute * 60 + second)  + 86400];
    NSLog(@"明天%@",nextDay);
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:nowDay endDate:nextDay options:(HKQueryOptionNone)];
    
    /*查询的基类是HKQuery，这是一个抽象类，能够实现每一种查询目标，这里我们需要查询的步数是一个HKSample类所以对应的查询类是HKSampleQuery。下面的limit参数传1表示查询最近一条数据，查询多条数据只要设置limit的参数值就可以了*/
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc]initWithSampleType:sampleType predicate:predicate limit:0 sortDescriptors:@[start,end] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        //设置一个int型变量来作为步数统计
        int allStepCount = 0;
        for (int i = 0; i < results.count; i ++) {
            //把结果转换为字符串类型
            HKQuantitySample *result = results[i];
            HKQuantity *quantity = result.quantity;
            NSMutableString *stepCount = (NSMutableString *)quantity;
            NSString *stepStr =[ NSString stringWithFormat:@"%@",stepCount];
            //获取51 count此类字符串前面的数字
            NSString *str = [stepStr componentsSeparatedByString:@" "][0];
            int stepNum = [str intValue];

            //把一天中所有时间段中的步数加到一起
            allStepCount = allStepCount + stepNum;
        }
        
        //查询要放在多线程中进行，如果要对UI进行刷新，要回到主线程
        [[NSOperationQueue mainQueue]addOperationWithBlock:^{
            self.todayStep.text = [NSString stringWithFormat:@"%d",allStepCount];
        }];
    }];
    //执行查询
    [self.healthStore executeQuery:sampleQuery];
}
@end
