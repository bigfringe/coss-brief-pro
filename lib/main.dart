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
class _BriefingHomeState extends State<BriefingHome> with SingleTickerProviderStateMixin {
  late final AnimationController trainMotion;
  @override void initState(){super.initState();trainMotion=AnimationController(vsync:this,duration:const Duration(seconds:9))..repeat();load();}
  @override void dispose(){trainMotion.dispose();super.dispose();}
  final Map<String,String> notes = {};
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
    if(mounted)setState(()=>loaded=true);
  }
  Future<void> save() async {
    final p=await SharedPreferences.getInstance();
    await p.setString('briefing',jsonEncode({'notes':notes,'crossed':crossed.toList()}));
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
          if(!excluded) TextFormField(key:ValueKey('field-$k'),initialValue:notes[k]??'',
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
    SizedBox(height:138,child:ClipRRect(borderRadius:BorderRadius.circular(16),child:AnimatedBuilder(
      animation:trainMotion,builder:(context,_)=>CustomPaint(
        painter:MovingTrainPainter(trainMotion.value),child:const SizedBox.expand())))),
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
  Widget buildPreview()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('COSS SAFETY BRIEFING – DRAFT',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    const SizedBox(height:8),
    const Text('Demonstration / draft only. Do not use as authority to work.',style:TextStyle(color:Colors.amber)),
    ...List.generate(headings.length,(i)=>Padding(padding:const EdgeInsets.only(top:20),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${i+1}. ${headings[i]}',style:Theme.of(context).textTheme.titleLarge),
        ...List.generate(options[i].length,(j){
          final k=keyFor(i,j);
          if(crossed.contains(k)||((notes[k]??'').trim().isEmpty))return const SizedBox.shrink();
          return Padding(padding:const EdgeInsets.only(top:8),child:Text('${options[i][j]}: ${notes[k]}'));
        })
      ]))),
    const SizedBox(height:24),
    const Text('Five-mile diagram attachments: planned for a later build.')
  ]);
}


// Lightweight, offline animated train header; no external image or network needed.
class MovingTrainPainter extends CustomPainter {
  MovingTrainPainter(this.progress);
  final double progress;
  @override void paint(Canvas canvas, Size size) {
    final w=size.width,h=size.height;
    final bg=Paint()..shader=const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,
      colors:[Color(0xff07131f),Color(0xff163247),Color(0xff17212a)]).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size,bg);
    final rail=Paint()..color=const Color(0xff9ba5a7)..strokeWidth=3;
    for(final y in [h*.79,h*.94]) {canvas.drawLine(Offset(0,y),Offset(w,y),rail);}
    final sleepers=Paint()..color=const Color(0xff61564a)..strokeWidth=5;
    for(double x=0;x<w;x+=27){canvas.drawLine(Offset(x,h*.78),Offset(x+9,h*.96),sleepers);}
    final overhead=Paint()..color=const Color(0xff4a5860)..strokeWidth=1.4;
    canvas.drawLine(Offset(0,h*.14),Offset(w,h*.14),overhead);
    for(double x=40;x<w;x+=125){canvas.drawLine(Offset(x,0),Offset(x,h*.17),overhead);}
    // Travel left to right; full consist passes and loops.
    final length=w*.86;
    final x=-length+(w+length)*progress;
    final y=h*.42;
    final train=Paint()..color=const Color(0xffe5ae29);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,length,h*.32),const Radius.circular(7)),train);
    canvas.drawRect(Rect.fromLTWH(x,y+h*.18,length,h*.07),Paint()..color=const Color(0xff142a42));
    final window=Paint()..color=const Color(0xff223b50);
    for(double wx=x+15;wx<x+length-38;wx+=33){canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx,y+8,23,h*.105),const Radius.circular(2)),window);}
    // Friendly conductor visible in the front side window, waving as the train passes.
    final cabX=x+length-51;
    final cabY=y+13;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cabX-5,cabY-5,29,27),const Radius.circular(5)),Paint()..color=const Color(0xff82b6d0));
    canvas.drawCircle(Offset(cabX+9,cabY+10),6,Paint()..color=const Color(0xffffc28d));
    canvas.drawRect(Rect.fromLTWH(cabX+3,cabY+16,14,7),Paint()..color=const Color(0xff182b4a));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cabX+2,cabY+2,15,5),const Radius.circular(2)),Paint()..color=const Color(0xff17243d));
    final wave=Paint()..color=const Color(0xffffc28d)..strokeWidth=3..strokeCap=StrokeCap.round;
    final handY=cabY+3+(progress<.5?3.0:0.0);
    canvas.drawLine(Offset(cabX+17,cabY+19),Offset(cabX+22,handY),wave);
    canvas.drawCircle(Offset(cabX+22,handY),3,wave);
    final nose=Path()..moveTo(x+length-24,y)..lineTo(x+length+8,y+15)..lineTo(x+length+8,y+h*.27)..lineTo(x+length-24,y+h*.32)..close();
    canvas.drawPath(nose,Paint()..color=const Color(0xfff4c84b));
    canvas.drawCircle(Offset(x+length+4,y+h*.21),4,Paint()..color=const Color(0xfffff7c5));
    final wheel=Paint()..color=const Color(0xff111820);
    for(double wx=x+20;wx<x+length;wx+=66){canvas.drawCircle(Offset(wx,y+h*.34),7,wheel);}
  }
  @override bool shouldRepaint(covariant MovingTrainPainter oldDelegate)=>oldDelegate.progress!=progress;
}
