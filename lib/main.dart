import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const CossApp());

const headings = <String>[
  'Introduction and Personnel','Work Location and Details','Safe System of Work',
  'Protection Arrangements','Access and Egress','Site Hazards and Risks',
  'Electrification','Plant and Equipment','Personal Protective Equipment',
  'Environmental Conditions','Emergency Arrangements','First Aid and Welfare',
  'Communications','Briefing Confirmation','Authority to Start Work',
  'Monitoring and Changes','Worksite Clearance','Handback and Sign-Off'
];
const options = <List<String>>[
  ['COSS name','Engineering Supervisor name','ES contact number','PICOP name','PICOP contact number','Other'],
  ['ELR','Track ID','Start mileage','Finish mileage','Access Point / Egress Point','Work description','Other'],
  ['Possession','Line blockage','Other authorised arrangement','Other'],
  ['Protection limits','Reference','Adjacent lines','Other'],
  ['Designated access','Designated egress','Walking route','Crossing point','Other'],
  ['Moving trains','Uneven ballast','Limited clearance','Noise','Poor visibility','Other'],
  ['25,000 V overhead line equipment','Nine-foot rule: verify applicability against current rules','DC third rail','DC fourth rail','Isolation arrangements','Return current / bonding','Other'],
  ['RRV','On-track machine','MEWP','Excavator','Rail grinder','Rail saw','Impact wrench','Generator','Lighting tower','Hand tools','Other'],
  ['High-visibility clothing','Safety footwear','Helmet','Gloves','Eye protection','Hearing protection','Other'],
  ['Rain','Snow / ice','Wind','Fog','Poor lighting','Other'],
  ['Emergency contact','Emergency access','Meeting point','Evacuation route','Other'],
  ['First aider','First aid kit','Hospital','Welfare','Other'],
  ['Mobile phone','Railway radio','Face-to-face','Communication failure','Other'],
  ['Briefing delivered','Questions answered','Understanding confirmed','Other'],
  ['Permission to start work granted','Worksite authority confirmed','Other'],
  ['Conditions changed','Reassessment','Rebrief required','Stop work','Other'],
  ['Machinery separation distance (metres)','Tools and plant clear','Personnel accounted for','Other'],
  ['Time requested to be clear (HH:MM)','Actual clearance time (HH:MM)','Handback confirmed','COSS sign-off','Other']
];

class CossApp extends StatelessWidget {
  const CossApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'COSS Brief Pro', theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffd8a93b), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xff13232c), useMaterial3: true),
    home: const BriefingHome());
}
class BriefingHome extends StatefulWidget {
  const BriefingHome({super.key});
  @override State<BriefingHome> createState() => _BriefingHomeState();
}
class _BriefingHomeState extends State<BriefingHome> with WidgetsBindingObserver {
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);load();}
  @override void dispose(){WidgetsBinding.instance.removeObserver(this);for(final controller in controllers.values){controller.dispose();}super.dispose();}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.inactive || state==AppLifecycleState.paused){save();}}
  final Map<String,String> notes = {};
  final Map<String,TextEditingController> controllers = {};
  Future<void> pendingSave = Future<void>.value();
  final Set<String> crossed = {};
  bool preview = false;
  bool loaded = false;
  String keyFor(int i,int j) => '$i:$j';
  Future<void> load() async {
    final p=await SharedPreferences.getInstance();
    final saved=p.getString('briefing');
    if(saved!=null) {
      try {
        final data=jsonDecode(saved) as Map<String,dynamic>;
        notes.addAll((data['notes'] as Map).map((k,v)=>MapEntry(k.toString(),v.toString())));
        crossed.addAll((data['crossed'] as List).map((v)=>v.toString()));
      } catch (_) {}
    }
    for(final entry in notes.entries){controllers[entry.key]=TextEditingController(text:entry.value);}
    if(mounted)setState(()=>loaded=true);
  }
  Future<void> save() {
    final snapshot=jsonEncode({'notes':notes,'crossed':crossed.toList()});
    pendingSave=pendingSave.catchError((Object error){debugPrint('Previous save failed: $error');}).then((_) async {
      final p=await SharedPreferences.getInstance();
      final ok=await p.setString('briefing',snapshot);
      if(!ok) throw StateError('Briefing save failed');
    });
    return pendingSave;
  }
  Widget field(int i,int j) {
    final k=keyFor(i,j), label=options[i][j], excluded=crossed.contains(k);
    return Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        IconButton(tooltip:excluded?'Restore item':'Cross out item',
          onPressed:(){setState((){if(excluded){crossed.remove(k);}else{crossed.add(k);}});save();},
          icon:Icon(excluded?Icons.cancel:Icons.circle_outlined,color:excluded?Colors.redAccent:Colors.amber)),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(label,style:TextStyle(decoration:excluded?TextDecoration.lineThrough:null)),
          if(!excluded) TextFormField(key:ValueKey('field-$k'),controller:controllers.putIfAbsent(k,()=>TextEditingController(text:notes[k]??'')),
            maxLines:null,decoration:InputDecoration(hintText:label=='Other'?'Enter other details':'Write details alongside this item',isDense:true),
            onChanged:(v){notes[k]=v;save();})
        ]))
      ]));
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar:AppBar(title:const Text('COSS Brief Pro'),actions:[
      IconButton(tooltip:'Save',onPressed:()async{await save();if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Draft saved on this device')));},icon:const Icon(Icons.save_outlined))
    ]),
    body:!loaded?const Center(child:CircularProgressIndicator()):preview?buildPreview():buildEditor(),
    bottomNavigationBar:SafeArea(child:Padding(padding:const EdgeInsets.all(12),
      child:FilledButton.icon(onPressed:(){setState(()=>preview=!preview);save();},
        icon:Icon(preview?Icons.edit:Icons.article),label:Text(preview?'Back to Edit':'ENTER – Written Briefing')))));
  Widget buildEditor()=>ListView(padding:const EdgeInsets.all(12),children:[
    SizedBox(height:138,child:ClipRRect(borderRadius:BorderRadius.circular(16),child:Image.asset(
      'Screenshot_20261029_151354_com_openai_chatgpt_MainActivity_edit_844638008552952.jpg',
      width:double.infinity,fit:BoxFit.cover,alignment:Alignment.center,
      errorBuilder:(context,error,stackTrace)=>const Center(child:Text('Train image unavailable'))))),
    const Padding(padding:EdgeInsets.symmetric(vertical:8,horizontal:4),child:Text(
      'Draft briefing only — verify safety arrangements before work.',
      style:TextStyle(fontSize:12,color:Colors.amber))),
    ...List.generate(headings.length,(i)=>Card(child:ExpansionTile(
      title:Text('${i+1}. ${headings[i]}', style:const TextStyle(color:Color(0xFFFFEB3B),fontSize:22,fontWeight:FontWeight.w900)),
      children:[Padding(padding:const EdgeInsets.all(12),child:Column(
        children:List.generate(options[i].length,(j)=>field(i,j))))]))),
    const Card(child:ListTile(leading:Icon(Icons.map_outlined),title:Text('19. Five-Mile Diagrams',style:TextStyle(color:Color(0xFFFFEB3B),fontSize:22,fontWeight:FontWeight.w900)),
      subtitle:Text('Photo upload and editable annotations planned for a later build.')))
  ]);
  // Spoken presentation is deterministic and offline: every saved active item
  // appears verbatim, without AI inventing or dropping safety-critical details.
  Widget buildPreview()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('COSS SAFETY BRIEFING – DRAFT',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    const SizedBox(height:8),
    const Text('Demonstration / draft only. Check all details against the approved briefing and current site arrangements. Not authority to work.',style:TextStyle(color:Colors.amber)),
    const SizedBox(height:18),
    Text('Morning everyone, I’m ${(notes[keyFor(0,0)]??'').trim().isEmpty ? '[COSS name not entered]' : notes[keyFor(0,0)]!.trim()}, your COSS today. I’ll run through the arrangements. You can ask questions during the briefing or at the end.'),
    ...List.generate(headings.length,(i){
      final active=<Widget>[];
      for(var j=0;j<options[i].length;j++){
        final k=keyFor(i,j);
        final value=(notes[k]??'').trim();
        if(crossed.contains(k)||value.isEmpty)continue;
        active.add(Padding(padding:const EdgeInsets.only(top:8),
          child:Text('${options[i][j]}: $value')));
      }
      return Padding(padding:const EdgeInsets.only(top:20),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('${i+1}. ${headings[i]}',style:Theme.of(context).textTheme.titleLarge),
          if(active.isEmpty)
            const Padding(padding:EdgeInsets.only(top:8),child:Text(
              'No details entered for this section. Check whether it needs completing before briefing.',
              style:TextStyle(color:Colors.amber))),
          ...active
        ]));
    }),
    const SizedBox(height:24),
    const Text('Five-mile diagram attachments: planned for a later build.'),
    const SizedBox(height:28),
    const Text('Final briefing confirmation',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    const SizedBox(height:12),
    const Text('That’s the briefing. Any questions, or anything you’d like me to explain again?'),
    const SizedBox(height:12),
    const Text('Does everybody understand the safe system of work, hazards and emergency arrangements? If not, please ask before we start.'),
    const SizedBox(height:12),
    const Text('If everyone understands, can I take your competency cards, please, to sign you in?'),
    const SizedBox(height:18),
    const Text('Do not proceed until questions have been answered and everyone has confirmed understanding.',style:TextStyle(color:Colors.amber)),
  ]);
}


// Detailed offline passenger train header, travelling left to right.
class MovingTrainPainter extends CustomPainter {
  MovingTrainPainter(this.progress);
  final double progress;
  @override void paint(Canvas canvas, Size size) {
    final w=size.width,h=size.height;
    canvas.drawRect(Offset.zero & size, Paint()..shader=const LinearGradient(
      begin:Alignment.topCenter,end:Alignment.bottomCenter,
      colors:[Color(0xff253b4c),Color(0xff7c909b),Color(0xff455760)]).createShader(Offset.zero & size));
    final ground=Paint()..color=const Color(0xff343b3e);
    canvas.drawRect(Rect.fromLTWH(0,h*.76,w,h*.24),ground);
    final ballast=Paint()..color=const Color(0xff646567);
    canvas.drawRect(Rect.fromLTWH(0,h*.83,w,h*.17),ballast);
    for(double i=0;i<w;i+=19) {
      canvas.drawLine(Offset(i,h*.86),Offset(i+12,h*.99),
        Paint()..color=const Color(0xff514b42)..strokeWidth=5);
    }
    for(final y in [h*.84,h*.96]) {
      canvas.drawLine(Offset(0,y),Offset(w,y),Paint()..color=const Color(0xffd0d1cd)..strokeWidth=3);
      canvas.drawLine(Offset(0,y+2),Offset(w,y+2),Paint()..color=const Color(0xff343a3d)..strokeWidth=1);
    }
    final wire=Paint()..color=const Color(0xff343d43)..strokeWidth=1.1;
    canvas.drawLine(Offset(0,h*.12),Offset(w,h*.12),wire);
    for(double px=30;px<w;px+=170) {
      canvas.drawLine(Offset(px,0),Offset(px,h*.19),wire);
      canvas.drawLine(Offset(px-18,h*.16),Offset(px+18,h*.16),wire);
    }
    // Two articulated passenger coaches with a rounded modern driving cab.
    final length=w*.98;
    final x=-length-30+(w+length+60)*progress;
    final top=h*.34, bodyH=h*.42, bottom=top+bodyH;
    final body=RRect.fromRectAndRadius(Rect.fromLTWH(x,top,length,bodyH),Radius.circular(h*.055));
    canvas.drawRRect(body,Paint()..color=const Color(0xffe3e7e7));
    canvas.drawRRect(body,Paint()..style=PaintingStyle.stroke..strokeWidth=1.2..color=const Color(0xffa7b2b6));
    canvas.drawRect(Rect.fromLTWH(x+2,top+h*.24,length-10,h*.07),Paint()..color=const Color(0xff174f7b));
    canvas.drawRect(Rect.fromLTWH(x+2,bottom-h*.055,length-13,h*.032),Paint()..color=const Color(0xff8c999d));
    // Roof equipment and seams.
    canvas.drawLine(Offset(x+18,top+3),Offset(x+length-31,top+3),
      Paint()..color=const Color(0xffa1adb2)..strokeWidth=2);
    for(final join in [x+length*.31,x+length*.63]) {
      canvas.drawLine(Offset(join,top+4),Offset(join,bottom-5),
        Paint()..color=const Color(0xff9ca7ac)..strokeWidth=2);
      canvas.drawRect(Rect.fromLTWH(join-3,bottom-7,6,6),Paint()..color=const Color(0xff25323a));
    }
    // Dark reflective glazing and thin aluminium surrounds.
    for(double wx=x+15;wx<x+length-68;wx+=37) {
      final rect=RRect.fromRectAndRadius(Rect.fromLTWH(wx,top+h*.075,27,h*.13),Radius.circular(3));
      canvas.drawRRect(rect,Paint()..color=const Color(0xff193547));
      canvas.drawLine(Offset(wx+5,top+h*.085),Offset(wx+12,top+h*.085),
        Paint()..color=const Color(0xff7c9aab)..strokeWidth=1.3);
    }
    // Passenger door pairs.
    for(final dx in [x+length*.27,x+length*.57]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(dx,top+h*.055,17,h*.31),Radius.circular(2)),
        Paint()..style=PaintingStyle.stroke..color=const Color(0xff7e8e94)..strokeWidth=1.5);
      canvas.drawLine(Offset(dx+8.5,top+h*.2),Offset(dx+8.5,bottom-h*.06),
        Paint()..color=const Color(0xff9ba8ac)..strokeWidth=1);
    }
    // Sloping aerodynamic driving end.
    final nose=Path()..moveTo(x+length-38,top+2)
      ..quadraticBezierTo(x+length+8,top+12,x+length+10,top+h*.21)
      ..lineTo(x+length+3,bottom-h*.08)
      ..quadraticBezierTo(x+length-4,bottom,x+length-38,bottom)
      ..close();
    canvas.drawPath(nose,Paint()..color=const Color(0xffe5e9e8));
    canvas.drawPath(nose,Paint()..style=PaintingStyle.stroke..strokeWidth=1.5..color=const Color(0xff96a5ab));
    final windscreen=Path()..moveTo(x+length-34,top+h*.055)
      ..quadraticBezierTo(x+length-2,top+h*.075,x+length+2,top+h*.19)
      ..lineTo(x+length-34,top+h*.19)..close();
    canvas.drawPath(windscreen,Paint()..color=const Color(0xff203c4e));
    canvas.drawLine(Offset(x+length-31,top+h*.067),Offset(x+length-13,top+h*.082),
      Paint()..color=const Color(0xff66889a)..strokeWidth=1.5);
    // Driver silhouette behind cab glass; a raised arm gives a small wave.
    final driverX=x+length-24, driverY=top+h*.125;
    canvas.drawCircle(Offset(driverX,driverY),h*.026,Paint()..color=const Color(0xffd8ae8a));
    canvas.drawLine(Offset(driverX+3,driverY+4),Offset(driverX+11,driverY-8),
      Paint()..color=const Color(0xffd8ae8a)..strokeWidth=2.5..strokeCap=StrokeCap.round);
    canvas.drawCircle(Offset(driverX+11,driverY-8),2.3,Paint()..color=const Color(0xffd8ae8a));
    // Cab lights and lower bogies.
    canvas.drawOval(Rect.fromCenter(center:Offset(x+length+2,top+h*.27),width:7,height:4),
      Paint()..color=const Color(0xfffff4cc));
    for(final bx in [x+length*.12,x+length*.41,x+length*.73]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx-15,bottom-2,35,7),Radius.circular(2)),
        Paint()..color=const Color(0xff20272b));
      for(final ox in [-8.0,12.0]) {
        canvas.drawCircle(Offset(bx+ox,bottom+4),5,Paint()..color=const Color(0xff171e22));
        canvas.drawCircle(Offset(bx+ox,bottom+4),2,Paint()..color=const Color(0xff8a9498));
      }
    }
  }
  @override bool shouldRepaint(covariant MovingTrainPainter oldDelegate)=>oldDelegate.progress!=progress;
}
