package br.com.smartcity.housecontrol.domain;

import lombok.Data;

import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.OneToMany;
import java.util.List;

@Data
@Entity
public class House {
    @Id
    private String id;
    private String name;

    @OneToMany
    private List<Device> devices;
}
