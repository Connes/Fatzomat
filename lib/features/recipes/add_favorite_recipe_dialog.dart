import 'package:flutter/material.dart';
import '../../core/async_error.dart';
import '../../data/repositories/recipe_repository.dart';

class AddFavoriteRecipeDialog extends StatefulWidget {
  const AddFavoriteRecipeDialog({super.key});
  @override State<AddFavoriteRecipeDialog> createState()=>_AddFavoriteRecipeDialogState();
}
class _AddFavoriteRecipeDialogState extends State<AddFavoriteRecipeDialog>{
  final name=TextEditingController(); final description=TextEditingController(); final ingredients=TextEditingController(); final steps=TextEditingController(); bool saving=false;
  @override void dispose(){name.dispose();description.dispose();ingredients.dispose();steps.dispose();super.dispose();}
  Future<void> save()async{if(name.text.trim().isEmpty)return;setState(()=>saving=true);try{final lines=ingredients.text.split('\n').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();await RecipeRepository().addFavoriteRecipe(name:name.text,description:description.text,instructions:steps.text.split('\n').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList(),ingredients:lines.map((line)=>{'food_id':null,'name':line,'quantity':1,'unit':'','is_user_selected':false,'is_additional':false,'is_qualitative':false}).toList());if(mounted)Navigator.pop(context,true);}catch(e){if(mounted)showAppError(context,e);}finally{if(mounted)setState(()=>saving=false);}}
  @override Widget build(BuildContext context)=>AlertDialog(title:const Text('Lieblingsrezept hinzufügen'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,autofocus:true,textCapitalization:TextCapitalization.sentences,decoration:const InputDecoration(labelText:'Rezeptname',hintText:'z. B. Familien-Lasagne')),const SizedBox(height:12),TextField(controller:description,maxLines:2,textCapitalization:TextCapitalization.sentences,decoration:const InputDecoration(labelText:'Kurzbeschreibung (optional)')),const SizedBox(height:12),TextField(controller:ingredients,maxLines:4,decoration:const InputDecoration(labelText:'Zutaten (eine pro Zeile, optional)')),const SizedBox(height:12),TextField(controller:steps,maxLines:4,decoration:const InputDecoration(labelText:'Zubereitung (ein Schritt pro Zeile, optional)'))]),actions:[TextButton(onPressed:saving?null:()=>Navigator.pop(context),child:const Text('Abbrechen')),FilledButton(onPressed:saving?null:save,child:Text(saving?'Speichern …':'Speichern'))]);
}
