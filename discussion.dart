import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ourwonderfullapp/Wrapper.dart';
import 'package:ourwonderfullapp/classes/Groupe.dart';
import 'package:ourwonderfullapp/classes/Message.dart';
import 'package:ourwonderfullapp/servises/storage.dart';
import 'package:ourwonderfullapp/classes/Utilisateur.dart';
import 'package:provider/provider.dart';

// ignore: camel_case_types
class chat extends StatefulWidget {
  final Group group;
  chat({this.group});
  @override
  _ChatState createState() => _ChatState();
}

// ignore: camel_case_types
class _ChatState extends State<chat> {
  String _messageText;
  Group _group ;
  Utilisateur _utilisateur ;
  Stream<QuerySnapshot> _messegesStream ;
  TextEditingController _messageComposer = TextEditingController ();
  final ScrollController _scrollController = ScrollController () ;
  final StorageService _storageService = StorageService ();

  _buildMessageComposer(TextEditingController messageComposer) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      height: 70.0,
      color:  Color(0xffF2E9DB),
      child: Row(
        children: <Widget>[
          IconButton(
              icon: Icon(Icons.photo),
              iconSize: 25.0,
              color: Color(0xff739D84),
              onPressed: () {}),
          Expanded(
              child: TextField(
                controller: messageComposer,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration.collapsed(
                  hintText: 'Envoyer un message...',
                ),
                onChanged: (value) {
                  _messageText = value ;
                },
              )),
          IconButton(
              icon: Icon(Icons.send),
              iconSize: 25.0,
              color: Color(0xff739D84),
              onPressed: () {
                _group.addMesssage(_messageText, TypeMessage.AboutGroupe, _utilisateur.sharableUserInfo.id, _utilisateur.sharableUserInfo.displayName);
                _scrollController.jumpTo(_scrollController.position.minScrollExtent);
                _messageComposer.clear();
              }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      _group = widget.group;
      _utilisateur = Provider.of<User>(context).utilisateur ;
      _messegesStream = _group.discussionCollection
      //.where('ShowTo', arrayContains: _utilisateur.sharableUserInfo.id)
          .snapshots(includeMetadataChanges: true);
    });
    return Scaffold(
        backgroundColor: Color(0xff739D84),
        appBar: AppBar(
          backgroundColor: Color(0xff739D84),
          title: Row(
            children: <Widget>[
              SizedBox(
                width: 30.0,
              ),
              //GroupeImageAsset(),
              FutureBuilder(
                future : _storageService.groupsImage(_group.photo, _group.groupPhoto),
                builder:(context,asyncSnapshot) =>  CircleAvatar(
                  backgroundImage: asyncSnapshot.data,
                  backgroundColor: Color(0xff739D84) ,
                ),
              ),
              SizedBox(
                width: 15.0,
              ),
              Text(
                _group.nom,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xffF2E9DB),
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          elevation: 0.0,
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.more_horiz),
                iconSize: 30.0,
                color: Color(0xffF2E9DB),
                onPressed: () {})
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xffF2E9DB),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30.0),
                        topRight: Radius.circular(30.0)),
                  ),
                  child: StreamBuilder<List<Message>>(
                    //initialData: _group.discussion,
                    stream: _messegesStream.map((querySnapshot) {
                      List<Message> messages = List<Message> () ;
                      querySnapshot.documents.forEach((document){
                        Message message = (Message.from(document.documentID,document.data));
                        if ((!querySnapshot.metadata.isFromCache) || (_group.lastReadMessage.compareTo(message.dateTime) >= 0))
                          message.sent = true ;
                        else
                          message.sent = false ;

                        if(_group.lastReadMessage.compareTo(message.dateTime) < 0){
                          _group.setLastReadMessage(message.dateTime);
                        }
                        messages.add(message);
                      });
                      //_group.discussion.addAll(messages);
                      return messages;
                    }),
                    builder: (buildContext,asyncSnapshot){
                      if (asyncSnapshot.hasError){
                        print(asyncSnapshot.error);
                        return Center(
                          child: Text('impossible de synchroniser') ,
                        );
                      }
                      else {
                        if(!asyncSnapshot.hasData){
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        else{
                          List<Message> messages = asyncSnapshot.data;
                          messages.sort();
                          return ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              itemCount: asyncSnapshot.data.length,
                              itemBuilder: (buildContext,int) {
                                Message thisMessage= messages[int];
                                return thisMessage == null ? Text('aucun message ajouté')
                                    : ListTile(
                                  title: _buildMessage(thisMessage),
                                  //SEEN BY
                                  onTap: (){
                                    showDialog(
                                        context: context,
                                        builder: (context){
                                          return Center(
                                            child: Expanded (
                                              child: ListView.builder(
                                                  itemBuilder: (context,int){
                                                    Member member = _group.member(thisMessage.seenBy[int]);
                                                    return ListTile(
                                                      title: Row(
                                                        children: <Widget>[
                                                          FutureBuilder(
                                                            future: _storageService.usersPhoto(member.membersInfo.photo,member.membersInfo.photoPath,member.membersInfo.gender),
                                                            builder: (context,asyncSnapshot) => CircleAvatar(
                                                              backgroundImage: asyncSnapshot.data,
                                                            ),
                                                          ),
                                                          Text(
                                                              Provider.of<User>(context).utilisateur.sharableUserInfo.id != member.membersInfo.id
                                                                  ? member.membersInfo.displayName
                                                                  : 'You'
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }
                                              ),
                                            ),
                                          );
                                        }
                                    );
                                  },
                                  //Delete
                                  onLongPress: () {
                                    showDialog (
                                      context : context ,
                                      builder: (context){
                                        return Container(
                                          child: Center(
                                            child: Column(
                                              children: <Widget>[
                                                SizedBox(height: 706,),
                                                Container(
                                                  height: 100,
                                                  width: 500,
                                                  color:Color(0xffF2E9DB) ,
                                                  child: Column(
                                                    children: <Widget>[
                                                      Row(
                                                        children: <Widget>[
                                                          FlatButton(
                                                            onPressed: () =>  _group.removeMessageForMe(_utilisateur.sharableUserInfo.id, thisMessage),
                                                            child: Text('Supprimer pour vous' ,
                                                              style: TextStyle(
                                                                  fontWeight: FontWeight.bold ,
                                                                  fontSize: 16 ,
                                                                  color: Color(0xff739D84)
                                                              ),),
                                                          ),
                                                          SizedBox(width: 50,),
                                                          Icon(
                                                            icon
                                                          )
                                                        ],
                                                      ),
                                                      _utilisateur.sharableUserInfo.id==thisMessage.expediteurID
                                                          ?  FlatButton(
                                                          onPressed: () => _group.removeMessageForEveryone(_utilisateur.sharableUserInfo.id, thisMessage) ,
                                                          child: Text('Supprimer pour tout le monde',
                                                              style: TextStyle(
                                                                  fontWeight: FontWeight.bold ,
                                                                  fontSize: 16 ,
                                                                  color: Color(0xff739D84)
                                                              ))
                                                      )
                                                          : null,
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              }
                          );
                        }
                      }
                    },
                  ),
                )),
            _buildMessageComposer(_messageComposer)
          ],
        ));
  }
  Widget _buildMessage(Message message){
    final bool fromMe  = message.expediteurID == _utilisateur.sharableUserInfo.id;
    final Container container =  Container (
      //TODO Marwa hadi ta3 alignment mahabatch torj
      margin: fromMe ? EdgeInsets.only(
        top: 8.0,
        bottom: 8.0 ,
        left: 90.0
      ) : EdgeInsets.only(
          top: 8.0,
          bottom: 8.0 ,
          right: 80.0
      ),
        padding: EdgeInsets.symmetric(horizontal: 10.0 , vertical: 1.0),
        decoration: BoxDecoration(
          color: fromMe ? Color(0xff739D84) : Color(0xffF1B97A),
          borderRadius: fromMe ? BorderRadius.only(
            topLeft: Radius.circular(15.0),
            bottomLeft: Radius.circular(15.0)
          ) : BorderRadius.only(
            topRight: Radius.circular(15.0) ,
            bottomRight: Radius.circular(15.0)
          )
        ),

        child: Column(
          children: <Widget>[


            fromMe? Row(
              children: <Widget>[
                Text(message.text , style: TextStyle( color : Color(0xffF2E9DB)),),
                IconButton(
                  color : Color(0xffF2E9DB),
                  icon: Icon(
                      //Message seen only by me
                      message.seenBy.length == 1 ?
                      message.sent ? Icons.check_circle: Icons.panorama_fish_eye
                      //Message seen
                      : Icons.remove_red_eye ),
                  onPressed: (){},
                ),
              ],
            )
            //From member
                : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children : <Widget>[
                FutureBuilder(
                  //future: _storageService.usersPhoto(_group.member(message.expediteurID).membersInfo.photo,_group.member(message.expediteurID).membersInfo.photoPath,_group.member(message.expediteurID).membersInfo.gender),
                  builder : (context,asyncSnapshot) => CircleAvatar(
                    backgroundImage: asyncSnapshot.data,
                    backgroundColor:Color(0xffF2E9DB) ,
                  ),
                ),
                SizedBox(width: 5.0,),
                Column (
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children : <Widget>[
                    Container(
                      alignment: Alignment.topRight,
                      child: Text(message.expediteurNom , style: TextStyle(color : Color(0xffF2E9DB)), textAlign: TextAlign.right,),
                    ),
                    Text(message.text ,  style: TextStyle(color : Color(0xffF2E9DB)),),
                  ],
                )
              ],
            ),
            Container(
              alignment: fromMe ? Alignment.topLeft : Alignment.topRight,
              child: Text(dateTimeToString(message.dateTime) , style: TextStyle(color: fromMe ? Color(0xffF2E9DB) : Color(0xffF2E9DB)), textAlign: fromMe ? TextAlign.left : TextAlign.right ),
            ),
          ],
        )
    );
    return container ;
  }
  String dateTimeToString (DateTime dateTime){
    var months = ['Janvier','Février','Mars','Avril','Mai','Juin','Juillet','Aout','Septembre','Octobre','Novembre','Decembre'];
    if (dateTime.day == DateTime.now().day && dateTime.month == DateTime.now().month && dateTime.year == DateTime.now().year )
      return dateTime.hour.toString()+':'+dateTime.minute.toString();
    else if (dateTime.year == DateTime.now().year)
      return dateTime.day.toString()+' '+months[dateTime.month];
    else
      return dateTime.day.toString()+' '+months[dateTime.month]+' '+dateTime.year.toString();
  }
}

/*class GroupeImageAsset extends StatelessWidget {
  final StorageService _storageService = StorageService ();

  @override
  Widget build(BuildContext context) {
    AssetImage assetImage = AssetImage(
      'groupe.png',
    );
    Image image = Image(image: assetImage, width: 40.0, fit: BoxFit.cover);
    return Container(
      child: image,
    );
  }
}*/
