package smart.city.org.eletric.control.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import java.util.concurrent.TimeUnit;

import smart.city.org.eletric.control.config.RabbitMQConfig;
import smart.city.org.eletric.control.entities.EnergySource;
import smart.city.org.eletric.control.exceptions.ResourceNotFoundException;
import smart.city.org.eletric.control.rabbitmq.MessageProducer;
import smart.city.org.eletric.control.repositories.EneregySourcesRepository;

import java.util.List;
import java.util.Optional;

@Service
public class EnergySourceService {


    private static final String PREFIXO_CACHE_ENERGYSOURCE= "ens:";
    @Autowired
    private EneregySourcesRepository eneregySourcesRepository;

    @Autowired
    private RedisTemplate<String, EnergySource> redisTemplate;

    @Autowired
    private MessageProducer messageProducer;


    public List<EnergySource> findAll() { return eneregySourcesRepository.findAll();}

    public EnergySource create(EnergySource energySource) {
        String cacheKey = PREFIXO_CACHE_ENERGYSOURCE + energySource.getId();
        redisTemplate.opsForValue().set(cacheKey, energySource, 1, TimeUnit.HOURS);

        EnergySource energySourceRet =  eneregySourcesRepository.save(energySource);
        messageProducer.sendMessage("Energy Cadastrada com sucesso");
        return energySourceRet;

    }

    public EnergySource findById(String id) throws ResourceNotFoundException {
        String cacheKey = PREFIXO_CACHE_ENERGYSOURCE + id;
        EnergySource energySourceredis = redisTemplate.opsForValue().get(cacheKey);
        if(energySourceredis!=null){

            return  energySourceredis;

        }

        Optional<EnergySource> energySource = eneregySourcesRepository.findById(id);

        if(energySource.isEmpty()) {
          throw new ResourceNotFoundException("Energy Source com " + id + "não foi encontrado");
        }
        redisTemplate.opsForValue().set(cacheKey, energySource.get(), 1, TimeUnit.HOURS);
        return energySource.get();
    }

    public boolean existsById (String id){


        return  eneregySourcesRepository.existsById(id);
    }

    public void deleteById(String id){
        String cacheKey = PREFIXO_CACHE_ENERGYSOURCE + id;
        redisTemplate.delete(cacheKey);
        eneregySourcesRepository.deleteById(id);

    }
    public void delete(EnergySource energySource){
        String cacheKey = PREFIXO_CACHE_ENERGYSOURCE + energySource.getId();
        redisTemplate.delete(cacheKey);
        eneregySourcesRepository.delete(energySource);
    }

}
