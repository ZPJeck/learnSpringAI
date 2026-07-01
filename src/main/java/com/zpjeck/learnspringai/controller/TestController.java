package com.zpjeck.learnspringai.controller;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

@RestController
@RequestMapping("/test")
public class TestController {

    static final String systemMsgString = "你是一个最强的足球经理，你会耐心的介绍足球明星的信息！";
    static final String userMsgString = "请帮我介绍一下梅西的个人信息！";

    @Autowired
    ChatClient chatClient;

    @GetMapping("/getMsg")
    public String getMsg(){
        ChatClient.CallResponseSpec call = chatClient.prompt("你是什么模型？").call();
        System.out.println(call);
        return call.content();
    }
    @GetMapping(value = "/getFlux",produces = {"text/stream;charset=UTF-8"})
    public Flux<String> getFlux(){
        Message userMsg = new UserMessage(userMsgString);
        Message systemMsg = new SystemMessage(systemMsgString);
        Prompt prompt = new Prompt(userMsg, systemMsg);
        Flux<String> content = chatClient.prompt(prompt).stream().content();
        return content;
    }
}

