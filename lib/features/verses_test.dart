import 'verse.dart';

/// TEST VERSES - for checking length limits and rendering
/// Switch to verses_data.dart in main.dart when done testing

const List<Verse> testVerses = [
  // === TINY (1 line) with MORE ===
  Verse(
    anchor: "Be still.",
    full: "Be still, and know that I am God. I will be exalted among the nations, I will be exalted in the earth! The Lord of hosts is with us; the God of Jacob is our fortress.",
    source: "Psalm 46:10-11",
    commentary: "The command to 'be still' (Hebrew: raphah) means to let go, to cease striving, to relax one's grip. It's an invitation to stop fighting and trust. This psalm was likely written after God delivered Jerusalem from the Assyrian army.",
  ),

  // === SHORT (2 lines) with MORE ===
  Verse(
    anchor: "The Lord is\nmy shepherd.",
    full: "The Lord is my shepherd; I shall not want. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul.",
    source: "Psalm 23:1-3",
    commentary: "David, a former shepherd himself, uses this intimate metaphor to describe God's care. The 'still waters' (Hebrew: mei menuchot) literally means 'waters of rest' — peaceful streams where sheep can drink safely.",
  ),

  // === MEDIUM (3-4 lines) with MORE ===
  Verse(
    anchor: "Be still,\nand know that\nI am God.",
    full: "Be still, and know that I am God. I will be exalted among the nations, I will be exalted in the earth!",
    source: "Psalm 46:10",
    commentary: "This verse comes in the context of a song celebrating God as a refuge and fortress. The command to 'be still' (Hebrew: raphah) means to let go, to cease striving, to relax one's grip. It's an invitation to stop fighting and trust.",
  ),

  // === MEDIUM with commentary only (no full text) ===
  Verse(
    anchor: "The light shines\nin the darkness,\nand the darkness\nhas not overcome it.",
    source: "John 1:5",
    commentary: "The Greek word for 'overcome' (katelaben) can also mean 'comprehend' or 'seize.' The darkness neither understood the light nor could extinguish it. This dual meaning enriches the verse's depth.",
  ),

  // === LONG (5-6 lines) with MORE ===
  Verse(
    anchor: "Trust in the Lord\nwith all your heart\nand lean not on\nyour own understanding;\nin all your ways\nsubmit to him.",
    full: "Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make straight your paths. Do not be wise in your own eyes; fear the Lord and shun evil.",
    source: "Proverbs 3:5-7",
    commentary: "The Hebrew word for 'trust' (batach) implies a sense of security and confidence, like lying down safely. 'Lean not' suggests not putting your weight on something — don't rely on your own limited perspective.",
  ),

  // === LONG without MORE (tests dimmed icon) ===
  Verse(
    anchor: "For everything\nthere is a season,\nand a time for\nevery matter\nunder heaven.",
    source: "Ecclesiastes 3:1",
  ),

  // === VERY LONG (auto-wrap) with MORE ===
  Verse(
    anchor: "For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.",
    full: "For I know the plans I have for you, declares the Lord, plans for welfare and not for evil, to give you a future and a hope. Then you will call upon me and come and pray to me, and I will hear you. You will seek me and find me, when you seek me with all your heart.",
    source: "Jeremiah 29:11-13",
    commentary: "Often quoted out of context, this promise was originally given to Israelites in Babylonian exile — a 70-year captivity. The 'plans' weren't for immediate rescue but for a long faithfulness. The hope is real, but so is the waiting.",
  ),

  // === SHORT with long commentary ===
  Verse(
    anchor: "Love is patient,\nlove is kind.",
    full: "Love is patient and kind; love does not envy or boast; it is not arrogant or rude. It does not insist on its own way; it is not irritable or resentful; it does not rejoice at wrongdoing, but rejoices with the truth. Love bears all things, believes all things, hopes all things, endures all things. Love never ends.",
    source: "1 Corinthians 13:4-8",
    commentary: "Paul wrote this to a church torn by division and competition over spiritual gifts. The Greek word for 'patient' (makrothymei) literally means 'long-tempered' — the opposite of quick-tempered. This love is not a feeling but a sustained choice.",
  ),

  // === TINY without MORE (tests dimmed icon) ===
  Verse(
    anchor: "Ask, and it\nwill be given.",
    source: "Matthew 7:7",
  ),

  // === MEDIUM with full only (no commentary) ===
  Verse(
    anchor: "Come to me,\nall who labor\nand are heavy laden,\nand I will give\nyou rest.",
    full: "Come to me, all who labor and are heavy laden, and I will give you rest. Take my yoke upon you, and learn from me, for I am gentle and lowly in heart, and you will find rest for your souls. For my yoke is easy, and my burden is light.",
    source: "Matthew 11:28-30",
  ),

  // === EXTRA LONG - stress test with MORE ===
  Verse(
    anchor: "Though the fig tree does not bud and there are no grapes on the vines, though the olive crop fails and the fields produce no food, though there are no sheep in the pen and no cattle in the stalls, yet I will rejoice in the Lord.",
    full: "Though the fig tree does not bud and there are no grapes on the vines, though the olive crop fails and the fields produce no food, though there are no sheep in the pen and no cattle in the stalls, yet I will rejoice in the Lord, I will be joyful in God my Savior. The Sovereign Lord is my strength; he makes my feet like the feet of a deer, he enables me to tread on the heights.",
    source: "Habakkuk 3:17-19",
    commentary: "Habakkuk wrote during a time of impending invasion. This is not denial of suffering but defiant hope — choosing joy not because circumstances are good, but because God remains. The 'deer's feet' metaphor speaks to sure-footedness in treacherous terrain.",
  ),

  // === FULL ONLY (no commentary) - long passages ===

  Verse(
    anchor: "In the beginning\nwas the Word.",
    full: "In the beginning was the Word, and the Word was with God, and the Word was God. He was in the beginning with God. All things were made through him, and without him was not any thing made that was made. In him was life, and the life was the light of men. The light shines in the darkness, and the darkness has not overcome it.",
    source: "John 1:1-5",
  ),

  Verse(
    anchor: "The Lord is\nmy light and\nmy salvation.",
    full: "The Lord is my light and my salvation; whom shall I fear? The Lord is the stronghold of my life; of whom shall I be afraid? When evildoers assail me to eat up my flesh, my adversaries and foes, it is they who stumble and fall. Though an army encamp against me, my heart shall not fear; though war arise against me, yet I will be confident.",
    source: "Psalm 27:1-3",
  ),

  Verse(
    anchor: "Create in me\na clean heart,\nO God.",
    full: "Create in me a clean heart, O God, and renew a right spirit within me. Cast me not away from your presence, and take not your Holy Spirit from me. Restore to me the joy of your salvation, and uphold me with a willing spirit. Then I will teach transgressors your ways, and sinners will return to you.",
    source: "Psalm 51:10-13",
  ),

  Verse(
    anchor: "I lift up my eyes\nto the hills.",
    full: "I lift up my eyes to the hills. From where does my help come? My help comes from the Lord, who made heaven and earth. He will not let your foot be moved; he who keeps you will not slumber. Behold, he who keeps Israel will neither slumber nor sleep. The Lord is your keeper; the Lord is your shade on your right hand.",
    source: "Psalm 121:1-5",
  ),

  Verse(
    anchor: "Where can I go\nfrom your Spirit?",
    full: "Where shall I go from your Spirit? Or where shall I flee from your presence? If I ascend to heaven, you are there! If I make my bed in Sheol, you are there! If I take the wings of the morning and dwell in the uttermost parts of the sea, even there your hand shall lead me, and your right hand shall hold me.",
    source: "Psalm 139:7-10",
  ),
];
