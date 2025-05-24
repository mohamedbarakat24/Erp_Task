import 'package:flutter/material.dart';
import 'package:erp_task/data/logic/folder/folder_bloc.dart';
import 'package:erp_task/data/logic/folder/folder_event.dart';
import 'package:erp_task/data/logic/document/document_bloc.dart';
import 'package:erp_task/data/logic/document/document_event.dart';
import 'screens/folder_list_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'core/constants/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => FolderBloc()..add(LoadFolders())),
        BlocProvider(create: (_) => DocumentBloc()..add(LoadDocuments())),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primaryClr,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryClr,
            foregroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.primaryClr,
            foregroundColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: AppColors.orangeClr,
            primary: AppColors.primaryClr,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: AppColors.darkGreyClr),
            bodyMedium: TextStyle(color: AppColors.darkGreyClr),
            titleLarge: TextStyle(color: AppColors.primaryClr),
          ),
        ),
        home: const FolderListScreen(),
      ),
    );
  }
}
