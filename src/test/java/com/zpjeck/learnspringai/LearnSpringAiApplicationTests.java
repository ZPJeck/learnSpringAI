package com.zpjeck.learnspringai;

import com.zpjeck.learnspringai.advisor.SimpleAdvisor;
import jakarta.annotation.Resource;
import org.junit.jupiter.api.Test;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.deepseek.DeepSeekChatModel;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import reactor.core.publisher.Flux;

@SpringBootTest
class LearnSpringAiApplicationTests {

//    @Autowired
//    OpenAiChatModel openAiChatModel;

    @Autowired
    DeepSeekChatModel deepSeekChatModel;

    @Resource
    ChatClient chatClient;

    static final String systemMsgString = "你是一个最强的足球经理，你会耐心的介绍足球明星的信息！";
    static final String userMsgString = "请帮我介绍一下梅西的个人信息！";

    @Test
    void contextLoads() {
        System.out.println(deepSeekChatModel.call("请识别我当前的项目并输出？"));
    }

    @Test
    public void testChatClient() {
//        System.out.println(chatClient.prompt().system(systemMsgString).user(userMsgString).call().content());
//        System.out.println("=============================================================================================");
//        System.out.println(chatClient.prompt(systemMsgString + userMsgString).call().content());
//        System.out.println("=============================================================================================");

        /**
         * 不同方式请求数据
         */
        Message userMsg = new UserMessage(userMsgString);
        Message systemMsg = new SystemMessage(systemMsgString);
        Prompt prompt = new Prompt(userMsg, systemMsg);
//        String content = chatClient.prompt(prompt).call().content();
//        System.out.println(content);
        System.out.println(chatClient.prompt(prompt).call().chatResponse());
    }
    @Test
    public void fluxChatClient() {
        Message userMsg = new UserMessage(userMsgString);
        Message systemMsg = new SystemMessage(systemMsgString);
        Prompt prompt = new Prompt(userMsg, systemMsg);
        Flux<String> content = chatClient.prompt(prompt).stream().content();
        content.doOnNext(System.out::println).blockLast();
    }

    @Test
    void testAdvisor() {
        String content = chatClient.prompt(systemMsgString + userMsgString).advisors(new SimpleAdvisor()).call().content();
        System.out.println(content);

    }




}
