import 'package:flutter/material.dart';
import 'package:feedbacks/login_screen.dart';
import 'package:feedbacks/pallet.dart';


void main() {
  runApp(const MyApp());
}


/// Este widget é Stateless porque suas configurações são fixas
/// e não mudam durante a execução do app.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Título do aplicativo 
      title: 'Feedbacks',
      
      // Remove a faixa "DEBUG" do canto superior direito
      debugShowCheckedModeBanner: false,
      
      
      // Partimos do tema escuro padrão (ThemeData.dark())
      // e personalizamos com copyWith()
      theme: ThemeData.dark().copyWith(

        // Define a cor de fundo padrão de todas as Scaffolds
        // A cor backgroundColor vem do arquivo pallet.dart
        scaffoldBackgroundColor: backgroundColor,
        
      ),
      
      // Tela inicial da aplicação
      home: const LoginScreen(),
  
    );
  }
}