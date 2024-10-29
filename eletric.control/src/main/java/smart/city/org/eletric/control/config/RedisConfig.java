package smart.city.org.eletric.control.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;
import smart.city.org.eletric.control.dto.EnergySourceDTO;
import smart.city.org.eletric.control.entities.EnergySource;

@Configuration
public class RedisConfig {

    @Bean
    public RedisTemplate<String, EnergySource> redisEnergySourceDTO(RedisConnectionFactory factory) {
        RedisTemplate<String, EnergySource> template = new RedisTemplate<>();
        template.setConnectionFactory(factory);

        template.setKeySerializer(new StringRedisSerializer());

        template.setValueSerializer(new GenericJackson2JsonRedisSerializer());

        return template;
    }

}