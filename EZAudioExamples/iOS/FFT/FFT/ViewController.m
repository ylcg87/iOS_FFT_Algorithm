//
//  ViewController.m
//  FFT
//
//  Created by Syed Haris Ali on 12/1/13.
//  Updated by Syed Haris Ali on 1/23/16.
//  Copyright (c) 2013 Syed Haris Ali. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "ViewController.h"

#define AUDIOFRAMELENGTH 1024
#define FFTSIZE 2048

static vDSP_Length const fftSize = FFTSIZE;
float audioFrame[FFTSIZE];

static const float freqBase[88] = {
    // Note A0 - B0
    27.5, 29.135235, 30.867706,
    // Note C1 - B1
    32.703195, 34.647828, 36.708095, 38.890872, 41.203444, 43.653528,
    46.249302, 48.999429, 51.913087, 55, 58.27047, 61.735412,
    // Note C2 - B2
    65.406391, 69.295657, 73.416191, 77.781745, 82.406889, 87.307057,
    92.498605, 97.998858, 103.82617, 110, 116.54094, 123.47082,
    // Note C3 - B3
    130.812782, 138.591315, 146.832383, 155.563491, 164.813778, 174.614115,
    184.997211, 195.997717, 207.652348, 220.000000, 233.081880, 246.941650,
    // Note C4 - B4
    261.625565, 277.182630, 293.664767, 311.126983, 329.627556, 349.228231,
    369.994422, 391.995435, 415.304697, 440.000000, 466.163761, 493.883301,
    // Note C5 - B5
    523.251130, 554.365261, 587.329535, 622.253967, 659.255113, 698.456462,
    739.988845, 783.990871, 830.609395, 880.000000, 932.327523, 987.766602,
    // Note C6 - B6
    1046.502261, 1108.730523, 1174.659071, 1244.507934, 1318.510227, 1396.912925,
    1479.97769, 1567.981743, 1661.21879, 1760, 1864.655046, 1975.533205,
    // Note C7 - B7
    2093.004522, 2217.461047, 2349.318143, 2489.015869, 2637.020455, 2793.825851,
    2959.955381, 3135.963487, 3322.43758, 3520, 3729.310092, 3951.06641,
    // Note C8
    4186.009044
};


@implementation ViewController

//------------------------------------------------------------------------------
#pragma mark - Status Bar Style
//------------------------------------------------------------------------------

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

//------------------------------------------------------------------------------
#pragma mark - View Lifecycle
//------------------------------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];

    //
    // Setup the AVAudioSession. EZMicrophone will not work properly on iOS
    // if you don't do this!
    //
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error)
    {
        NSLog(@"Error setting up audio session category: %@", error.localizedDescription);
    }
    [session setActive:YES error:&error];
    if (error)
    {
        NSLog(@"Error setting up audio session active: %@", error.localizedDescription);
    }

    //
    // Add user startup functions
    //
    // Add zero padding if needed
    if (FFTSIZE > AUDIOFRAMELENGTH) {
        for (int i = AUDIOFRAMELENGTH; i < FFTSIZE; i++) {
            audioFrame[i] = 0;
        }
    }
    
    //
    // Setup time domain audio plot
    //
    self.audioPlotTime.plotType = EZPlotTypeBuffer;
    self.maxFrequencyLabel.numberOfLines = 0;

    //
    // Setup frequency domain audio plot
    //
    self.audioPlotFreq.shouldFill = YES;
    self.audioPlotFreq.plotType = EZPlotTypeBuffer;
    self.audioPlotFreq.shouldCenterYAxis = NO;

    //
    // Create an instance of the microphone and tell it to use this view controller instance as the delegate
    //
    self.microphone = [EZMicrophone microphoneWithDelegate:self withAudioStreamBasicDescription:[self customAudioStreamBasicDescriptionWithSampleRate:44100.f]];

    //
    // Create an instance of the EZAudioFFTRolling to keep a history of the incoming audio data and calculate the FFT.
    //
    self.fft = [EZAudioFFT fftWithMaximumBufferSize:fftSize sampleRate:self.microphone.audioStreamBasicDescription.mSampleRate delegate:self];

    //
    // Start the mic
    //
    [self.microphone startFetchingAudio];
    
}

//------------------------------------------------------------------------------
#pragma mark - EZMicrophoneDelegate
//------------------------------------------------------------------------------

-(void)    microphone:(EZMicrophone *)microphone
     hasAudioReceived:(float **)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels
{
    //
    // Update audioData
    //
    for (int i = 0; i < AUDIOFRAMELENGTH-bufferSize; i++)
        audioFrame[i] = audioFrame[i+bufferSize];
    for (int i = 0; i < bufferSize; i++)
        audioFrame[AUDIOFRAMELENGTH-bufferSize+i] = buffer[0][i];
    
    //
    // Calculate the FFT, will trigger EZAudioFFTDelegate
    //
    [self.fft computeFFTWithBuffer:audioFrame withBufferSize:FFTSIZE];

    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.audioPlotTime updateBuffer:buffer[0]
                              withBufferSize:bufferSize];
    });
}

//------------------------------------------------------------------------------
#pragma mark - EZAudioFFTDelegate
//------------------------------------------------------------------------------

- (void)        fft:(EZAudioFFT *)fft
 updatedWithFFTData:(float *)fftData
         bufferSize:(vDSP_Length)bufferSize
{
    float maxFrequency = [fft maxFrequency];
    float maxFrequencyMagnitude = [fft maxFrequencyMagnitude];
    NSString *noteName = [EZAudioUtilities noteNameStringForFrequency:maxFrequency
                                                        includeOctave:YES];

    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.maxFrequencyLabel.text = [NSString stringWithFormat:@"Highest Note: %@,\nFrequency: %.2f", noteName, maxFrequency];
        [weakSelf.audioPlotFreq updateBuffer:fftData withBufferSize:(UInt32)bufferSize];
    });
}

/**
 音频捕获参数设置
 
 @return return value description
 */
- (AudioStreamBasicDescription)customAudioStreamBasicDescriptionWithSampleRate:(CGFloat)sampleRate
{
    AudioStreamBasicDescription asbd;
    UInt32 floatByteSize   = sizeof(float);
    // 每个通道中的位数，1byte = 8bit
    asbd.mBitsPerChannel   = 8 * floatByteSize;
    // 每一帧中的字节数
    asbd.mBytesPerFrame    = floatByteSize;
    // 一个数据包中的字节数
    asbd.mBytesPerPacket   = floatByteSize;
    // 每一帧数据中的通道数，单声道为1，立体声为2
    asbd.mChannelsPerFrame = 1;
    // 每种格式特定的标志，无损编码 ，0表示没有
    asbd.mFormatFlags      = kAudioFormatFlagIsFloat|kAudioFormatFlagIsNonInterleaved;
    // 采样数据的类型，PCM,AAC等
    asbd.mFormatID         = kAudioFormatLinearPCM;
    // 一个数据包中的帧数，每个packet的帧数。如果是未压缩的音频数据，值是1。动态帧率格式，这个值是一个较大的固定数字，比如说AAC的1024。如果是动态大小帧数（比如Ogg格式）设置为0。
    asbd.mFramesPerPacket  = 1;
    // 设置采样率：Hz
    // 采样率：Hz
    asbd.mSampleRate       = sampleRate;
    return asbd;
}

@end
