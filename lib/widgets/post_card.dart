import 'package:flutter/material.dart';

import '../models/post.dart';
import '../pages/login_page.dart'; // usa kPrimary e kFont

class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: kPrimary,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  post.autor,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.texto,
            style: const TextStyle(
              fontFamily: kFont,
              fontSize: 11.5,
              height: 1.35,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.8,
              child: Container(height: 1, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}
