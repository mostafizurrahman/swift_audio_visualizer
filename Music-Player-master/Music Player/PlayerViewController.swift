//
//  ViewController.swift
//  Music Player
//
//  Created by polat on 19/08/14.
//  Copyright (c) 2014 polat. All rights reserved.
// contact  bpolat@live.com

// Build 3 - July 1 2015 - Please refer git history for full changes
// Build 4 - Oct 24 2015 - Please refer git history for full changes

//Build 5 - Dec 14 - 2015 Adding shuffle - repeat
//Build 6 - Oct 10 - 2016 iOS 10 update - iPhone 3g, 3gs screensize no more supported.



import UIKit
import AVFoundation
import MediaPlayer


extension UIImageView {
    
    func setRounded() {
        let radius = self.frame.width / 2
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}

//metering for visualization
//https://www.raywenderlich.com/2714-how-to-make-a-music-visualizer-in-ios




class PlayerViewController: UIViewController,AVAudioPlayerDelegate {
    
    
    var audioPlayer:AVAudioPlayer! = nil
    
    var audioData:AudioData? {
        didSet{
            self.setCurrentAudioPath()
        }
    }
    
    var currentAudioPath:URL!
    
    var audioLength = 0.0
    var totalLengthOfAudio = ""
    var updater:CADisplayLink?
    
    @IBOutlet weak var audioVisualizationView: AudioAnimationView!
    @IBOutlet var songNameLabel : UILabel!
    @IBOutlet var progressTimerLabel : UILabel!
    @IBOutlet var playerProgressSlider : UISlider!
    @IBOutlet var totalLengthOfAudioLabel : UILabel!
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.updater?.isPaused = true
        if let _player = self.audioPlayer {
            _player.pause()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        assingSliderUI()
        updater = CADisplayLink(target: self, selector: #selector(updateUI))
        updater?.add(to: .current, forMode: .defaultRunLoopMode)
        updater?.isPaused = true
        
        
    }

    deinit {
        updater?.invalidate()
        
    }
    
    
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK:- AVAudioPlayer Delegate's Callback method
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool){
        if flag == true {
//            self.audioPlayer.
          
        }
    }
    
    
    //Sets audio file URL
    func setCurrentAudioPath(){
        if let _audio_data = self.audioData,
            let _audio_file = _audio_data.clean_path {
            if _audio_file.elementsEqual("sample_clean") {
                if let _audio = Bundle.main.url(forResource: "sample_denoised", withExtension: "MP3") {
                    self.currentAudioPath = _audio
                    self.songNameLabel.text = "clean_sample_audio.mp3"
                }
            } else if _audio_file.elementsEqual("sample_noise"){
                if let _audio = Bundle.main.url(forResource: "sample_noisy_file", withExtension: "mp3") {
                    self.currentAudioPath = _audio
                    self.songNameLabel.text = "original_sample_audio.mp3"
                }
            } else {
                var audioPath = AudioFileManager.getDocumentsDirectory()
                audioPath.appendPathComponent("audio_files")
                audioPath.appendPathComponent(_audio_file)
                self.songNameLabel.text = _audio_file
                self.currentAudioPath = audioPath
            }
            prepareAudio()
            DispatchQueue.main.async {
                self.songNameLabel.text = (_audio_file as NSString ).lastPathComponent
            }
            prepareAudio()
        }
        
    }



    
    // Prepare audio for playing
    func prepareAudio(){
        
        do {
            //keep alive audio at background
         
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: currentAudioPath)
            
            audioPlayer.delegate = self
            audioLength = audioPlayer.duration
            playerProgressSlider.maximumValue = CFloat(audioPlayer.duration)
            playerProgressSlider.minimumValue = 0.0
            playerProgressSlider.value = 0.0
            audioPlayer.prepareToPlay()
            showTotalSongLength()
            progressTimerLabel.text = "00:00"
            //try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        } catch  {
            print(error)
        }
        
        
        
    }
    
    //MARK:- Player Controls Methods
    func  playAudio()->Bool{
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        } catch {
            print(error)
        }
        self.audioVisualizationView.shouldClearContext = true
        if audioPlayer == nil {
            return false
        }
        audioPlayer.play()
        updater?.isPaused = false
        return true
    }

    
    func stopAudiplayer(){
        audioPlayer.stop();
        updater?.isPaused = true
    }
    
    func pauseAudioPlayer(){
        audioPlayer.pause()
    }
    
    func resumeAudioPlayer()  {
        audioPlayer.play()
        updater?.isPaused = false
    }
    
    func resetAudioPlayer() {
        self.totalLengthOfAudioLabel.text = "00:00"
        self.progressTimerLabel.text = "00:00"
        self.audioVisualizationView.shouldClearContext = true
        self.playerProgressSlider.value = 0.0
    }
    
    @objc func updateUI(){
        if let player = self.audioPlayer {
            self.update()
            player.isMeteringEnabled = true
            if player.isPlaying {
                // 2
                player.updateMeters()
                
                // 3
                var power:Float = 0.0
                for i in 0..<player.numberOfChannels {
                    let pw = player.averagePower(forChannel: i)
                    print(pw)
                    power += pw
                }
                power /= Float(player.numberOfChannels)
                
                // 4
                let level = getMeterLevel(Decible: power)
                let scale = level * Float(self.audioVisualizationView.frame.height)
                self.audioVisualizationView.barHeight = Int(scale)
            }
        }
    }
    
    var mTable:UnsafeMutablePointer<Float>?
    var mDecibelResolution:Float = -1
    var mScaleFactor:Float = 0.0
    func getMeterLevel(Decible inDecibels:Float)->Float {
        let mMinDecibels:Float = -80.0
        let inTableSize:Int = 800
        let inRoot:Float = 1.5
        if mDecibelResolution == -1.0 {
            self.mDecibelResolution = mMinDecibels / Float(inTableSize - 1)
            self.mScaleFactor = 1.0 / mDecibelResolution
        }
        if (inDecibels < mMinDecibels) {return  0.0}
        if (inDecibels >= 0.0) {return 1.0}
        let index = Int(inDecibels * mScaleFactor);
        if let inTable = self.mTable {
            return inTable[index];
        } else {
            self.mTable = UnsafeMutablePointer<Float>.allocate(capacity: inTableSize)
            let minAmp = pow(10.0, 0.05 * mMinDecibels)
            let ampRange = 1.0 - minAmp;
            let invAmpRange = 1.0 / ampRange;
            
            let rroot = 1.0 / inRoot;
            for i in 0...799 {
                let decibels = Float(i) * mDecibelResolution;
                let amp = pow(10.0, 0.05 * decibels)
                let adjAmp = (amp - minAmp) * invAmpRange;
                self.mTable?[i] = pow(adjAmp, rroot);
            }

            return self.mTable![index];
        }
    }
    
   
    
    
    @objc func update(){
        if !audioPlayer.isPlaying{
            return
        }
        let time = calculateTimeFromNSTimeInterval(audioPlayer.currentTime)
        progressTimerLabel.text  = "\(time.minute):\(time.second)"
        playerProgressSlider.value = CFloat(audioPlayer.currentTime)
    }
 
    //This returns song length
    func calculateTimeFromNSTimeInterval(_ duration:TimeInterval) ->(minute:String, second:String){
       // let hour_   = abs(Int(duration)/3600)
        let minute_ = abs(Int((duration/60).truncatingRemainder(dividingBy: 60)))
        let second_ = abs(Int(duration.truncatingRemainder(dividingBy: 60)))
        
       // var hour = hour_ > 9 ? "\(hour_)" : "0\(hour_)"
        let minute = minute_ > 9 ? "\(minute_)" : "0\(minute_)"
        let second = second_ > 9 ? "\(second_)" : "0\(second_)"
        return (minute,second)
    }
    

    
    func showTotalSongLength(){
        calculateSongLength()
        totalLengthOfAudioLabel.text = totalLengthOfAudio
    }
    
    
    func calculateSongLength(){
        let time = calculateTimeFromNSTimeInterval(audioLength)
        totalLengthOfAudio = "\(time.minute):\(time.second)"
    }
    
    func assingSliderUI () {
        
        let thumb = UIImage(named: "thumb")

        
        playerProgressSlider.setThumbImage(thumb, for: UIControlState())

    
    }
    
    func play() {
        if audioPlayer.isPlaying{
            pauseAudioPlayer()
        }else{
            playAudio()
        }
    }
    
    @IBAction func changeAudioLocationSlider(_ sender : UISlider) {
        audioPlayer.currentTime = TimeInterval(sender.value)
        
    }
}
