package smart.city.org.eletric.control.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import smart.city.org.eletric.control.entities.Battery;
import smart.city.org.eletric.control.entities.EnergySource;
import smart.city.org.eletric.control.exceptions.ResourceNotFoundException;
import smart.city.org.eletric.control.repositories.BatteryRepository;
import smart.city.org.eletric.control.repositories.EneregySourcesRepository;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

public class BatteryService {
    private static final String PREFIXO_CACHE_BATTERY= "ens:";

    @Autowired
    private BatteryRepository batteryRepository;

    @Autowired
    private RedisTemplate<String, Battery> redisTemplate;

    public List<Battery> findAll() { return batteryRepository.findAll();}

    public Battery create(Battery battery) {
        String cacheKey = PREFIXO_CACHE_BATTERY + battery.getId();
        redisTemplate.opsForValue().set(cacheKey, battery, 1, TimeUnit.HOURS);

        Battery batteryReturn =  batteryRepository.save(battery);
        return batteryReturn;
    }

    public Battery findById(String id) throws ResourceNotFoundException {
        String cacheKey = PREFIXO_CACHE_BATTERY + id;
        Battery batteryRedis = redisTemplate.opsForValue().get(cacheKey);
        if(batteryRedis!=null){

            return  batteryRedis;

        }

        Optional<Battery> battery = batteryRepository.findById(id);

        if(battery.isEmpty()) {
            throw new ResourceNotFoundException("Energy Source com " + id + "não foi encontrado");
        }
        redisTemplate.opsForValue().set(cacheKey, battery.get(), 1, TimeUnit.HOURS);
        return battery.get();
    }

    public boolean existsById (String id){


        return  batteryRepository.existsById(id);
    }

    public void deleteById(String id){
        String cacheKey = PREFIXO_CACHE_BATTERY + id;
        redisTemplate.delete(cacheKey);
        batteryRepository.deleteById(id);

    }
    public void delete(Battery battery){
        String cacheKey = PREFIXO_CACHE_BATTERY + battery.getId();
        redisTemplate.delete(cacheKey);
        batteryRepository.delete(battery);
    }



}